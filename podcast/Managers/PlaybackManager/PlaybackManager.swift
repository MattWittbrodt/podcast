//
//  PlaybackManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import AVKit
import MediaPlayer
import Combine
import CoreData

@Observable
class PlaybackManager {
    private let dataManager: DataManager
    private var settingsRepository: SettingsRepository
    private let saveFrequency: TimeInterval = 5
    
    // Hook to allow Use Cases to listen for the end event
    private var cancellables = Set<AnyCancellable>()
    var onEpisodeEnded: (() -> Void)?
    
    // MARK: - Published Properties
    var currentEpisode: EpisodeRecord?
    var lastListened: TimeInterval = 0
    var playbackState: PlaybackState = .stopped
    var currentTime: Double = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1
    var isSeeking = false
    var isPlaying: Bool = false
    var currentAudioDeviceName: String? = nil
    var currentEpisodeImage: UIImage? = nil
    
    var player = AVPlayer()
    private var timeObserver: Any?
    
    var timeStream: AsyncStream<TimeInterval>?
    private var continuation: AsyncStream<TimeInterval>.Continuation?
    
    init(dataManager: DataManager, settingsRepository: SettingsRepository) {
        self.dataManager = dataManager
        self.settingsRepository = settingsRepository
        setupAudioSession()
        setupPlaybackObservers()
        
        // Stream and its continuation live forever
        // Only one AVPlayer, only one time observer needed
        var cont: AsyncStream<TimeInterval>.Continuation?
        timeStream = AsyncStream { cont = $0 }
        continuation = cont
        
        // One time observer for the lifetime of the manager
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, self.isPlaying else { return }
            guard self.isSeeking == false else { return }
            self.updateNowPlayingInfo()
            
            if let audioOutput = AVAudioSession.sharedInstance().currentRoute.outputs.first {
                if audioOutput.portType == .builtInSpeaker {
                    self.currentAudioDeviceName = nil
                } else if audioOutput.portName != self.currentAudioDeviceName {
                    self.currentAudioDeviceName = audioOutput.portName
                }
            }
            self.continuation?.yield(time.seconds)
        }
    }
    
    // Sets up observer for end of episode using AVPlayerItemDidPlayToEndTime
    private func setupPlaybackObservers() {
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] notification in
                guard let item = notification.object as? AVPlayerItem else { return }
                guard item == self?.player.currentItem else { return }
                self?.onEpisodeEnded?()
            }
            .store(in: &cancellables)
    }
    
    func startPlayback(episode: EpisodeRecord) {
        self.cleanupPlayer()
        
        currentEpisode = episode
        duration = Double(episode.duration)
        
        let playerItem = AVPlayerItem(url: episode.audioUrl)
        player.replaceCurrentItem(with: playerItem)
        //player = AVPlayer(playerItem: playerItem)
        
        Task { [weak self] in
                guard let self else { return }
                
                // Load duration directly from asset — more reliable than item.duration
                let asset = playerItem.asset
                do {
                    let duration = try await asset.load(.duration)
                    let seconds = duration.seconds
                    if seconds.isFinite && seconds > 0 {
                        await MainActor.run { self.duration = seconds }
                    }
                } catch {
                    print("failed to load duration: \(error)")
                }
            }
        
        
        self.seek(to: episode.lastListened)
        self.playbackRate = episode.playbackRate
        
        // TODO: Use something like setupItemStatusObservation(for item: AVPlayerItem) when adding streaming
        player.play()
        player.rate = self.playbackRate
        isPlaying = true
        //startProgressUpdates()
        setupRemoteTransportControls()
        
        setupNowPlayingInfo()
    }
    
    // Handles the destruction of player object
    func cleanupPlayer() {
        player.pause()
        isPlaying = false
        currentTime = 0.0
        lastListened = 0.0
    }
    
}

// MARK: Manage Playback Directly
extension PlaybackManager {
    func playPause() {

        switch player.timeControlStatus {
        case .playing, .waitingToPlayAtSpecifiedRate:
            player.pause()
            isPlaying = false
        case .paused:
            player.rate = self.playbackRate
            isPlaying = true
        @unknown default:
            break
        }
    }
    
    func skipForward(seconds: Int64) {
        let newTime = player.currentTime() + CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
    }
    
    func skipBackward(seconds: Int64) {
        let newTime = player.currentTime() - CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
    }
    
    func seek(to time: Double) {
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        
        // Use a weak tolerance for fast updates, or kCMTimeZero for accuracy
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            // When seeking is complete, ensure currentTime is updated (optional, as observer should take over)
            //self?.currentTime = CMTimeGetSeconds(player.currentTime())
            // You might need logic here to ensure playback resumes if it was paused before seeking
        }
    }
    
    func updatePlaybackRate(_ rate: Float) {
        self.playbackRate = rate
        player.rate = rate
        if !self.isPlaying {
            self.isPlaying = true
        }
    }
    
    func setCurrentEpisodeImage(img: UIImage) {
        self.currentEpisodeImage = img
    }
}

// MARK: Monitoring player state
extension PlaybackManager {
    
    private func stopProgressUpdates() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
}

extension PlaybackManager {
    enum PlaybackState {
        case stopped, loading, playing, paused, failed(Error)
    }
    
    struct PlaybackError: LocalizedError {
        let errorDescription: String?
    }
}

//MARK: Command Center and NowPlayingInfo
extension PlaybackManager {
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remove previous targets to avoid duplicates
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playPause()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playPause()
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: settingsRepository.settings.backwardSkip)]
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: Int64(self?.settingsRepository.settings.backwardSkip ?? 30))
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]//settingsRepository.settings.forwardSkip)]
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: Int64(self?.settingsRepository.settings.forwardSkip ?? 30))
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: Double(event.positionTime))
            }
            return .success
        }
    }
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentEpisode?.episodeTitle ?? "Episode Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentEpisode?.podcastTitle ?? "Podcast Name"
        
        // Set artwork if available
        if let image = self.currentEpisodeImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlayingInfo() {
        guard let episode = currentEpisode else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.episodeTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.podcastTitle
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = episode.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            
        if let image = self.currentEpisodeImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
