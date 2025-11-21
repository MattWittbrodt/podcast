//
//  PlaybackManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import AVKit
import MediaPlayer

@MainActor
class PlaybackManager: ObservableObject {
    private let downloadManager: DownloadManager
    private let dataManager: DataManager
    private let saveFrequency: TimeInterval = 5
    
    // MARK: - Published Properties
    //@Published var showPlayerSheet: Bool = false
    @Published var currentEpisode: Episode?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: Double = 0
    @Published var currentTimeString: String = "00:00:00"
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1
    @Published var isSeeking = false
    @Published var isPlaying: Bool = false
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    init(downloadManager: DownloadManager, dataManager: DataManager) {
        self.downloadManager = downloadManager
        self.dataManager = dataManager
        setupAudioSession()
        setupCombineSubscribers()
    }
    
    // Mapping to update the string representation of current time appropriately
    func setupCombineSubscribers() {
        $currentTime
            .map { formattedTime(time: $0) }
            .assign(to: &$currentTimeString)
    }
    
    func startPlayingEpisode(episode: Episode) {
        self.cleanupPlayer()
        
        var urlToPlay: URL? = nil
        
        if let localPath = downloadManager.getFullDownloadPath(for: episode),
           downloadManager.downloadFileExists(for: episode) {
            print("⬇️ ✅ Found download")
            urlToPlay = localPath
        } else if let remoteURLString = episode.enclosureUrl,
                 let remoteURL = URL(string: remoteURLString) {
            urlToPlay = remoteURL
            print("Playing episode by streaming from remote URL.")
        } else {
            print("Error: Invalid episode URL and no local file found.")
            return
        }
        
        guard let finalUrl = urlToPlay else {
            print("Error: Invalid episode URL and no local file found.")
            return
        }
        
        currentEpisode = episode
        duration = Double(episode.duration)
        
        let playerItem = AVPlayerItem(url: finalUrl)
        player = AVPlayer(playerItem: playerItem)
        self.seek(to: episode.lastListened)
        self.playbackRate = currentEpisode?.podcast?.playbackRate ?? 1.0
        
        // TODO: Use something like setupItemStatusObservation(for item: AVPlayerItem) when adding streaming
        player?.play()
        player?.rate = self.playbackRate
        isPlaying = true
        startProgressUpdates()
        setupRemoteTransportControls()
        setupNowPlayingInfo()
    }
    
    // Handles the destruction of player object
    func cleanupPlayer() {
        player?.pause()
        isPlaying = false
        currentTime = 0.0
        stopProgressUpdates()
        player = nil
    }
}

// MARK: Manage Playback Directly
extension PlaybackManager {
    func playPause() {
        guard let player = player else { return }

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
        guard let player = player else { return }
        let newTime = player.currentTime() + CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
    }
    
    func skipBackward(seconds: Int64) {
        guard let player = player else { return }
        let newTime = player.currentTime() - CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
    }
    
    func seek(seconds: Int64) {
        guard let player = player else { return }
        player.seek(to: CMTime(value: seconds, timescale: 1))
    }
    
    func seek(to time: Double) {
        guard let player = player else { return }
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        
        // Use a weak tolerance for fast updates, or kCMTimeZero for accuracy
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            // When seeking is complete, ensure currentTime is updated (optional, as observer should take over)
            self?.currentTime = CMTimeGetSeconds(player.currentTime())
            self?.isSeeking = false
            // You might need logic here to ensure playback resumes if it was paused before seeking
        }
    }
    
    func updatePlaybackRate(_ rate: Float) {
        guard let currentEpisode = currentEpisode, let podcast = currentEpisode.podcast, let player = self.player else { return }
        self.dataManager.updatePodcastRate(podcast, rate: rate )
        self.playbackRate = rate
        player.rate = rate
    }
}

// MARK: Monitoring player state
extension PlaybackManager {
    @MainActor
    private func startProgressUpdates() {
        stopProgressUpdates()
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                // Save current time and update now playing
                self?.currentTime = time.seconds
                self?.updateNowPlayingInfo()
                
                guard let saveFrequency = self?.saveFrequency, let currentEpisode = self?.currentEpisode else { return }
                if time.seconds - currentEpisode.lastListened > saveFrequency {
                    self?.dataManager.saveEpisodeTime(currentEpisode, time: time.seconds)
                }
            }
        }
    }
    
    @MainActor
    private func stopProgressUpdates() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
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
        
        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: 30)
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 30)
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(seconds: Int64(event.positionTime))
            }
            return .success
        }
    }
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentEpisode?.title ?? "Episode Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentEpisode?.podcast?.title ?? "Podcast Name"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Album"
        
        // Set artwork if available
        if let image = UIImage(named: "AlbumArt") {
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
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.podcast?.title
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = episode.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
            
//        if let data = self.episodeImageData, let image = UIImage(data: data) {
//            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
//        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
