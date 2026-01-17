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
    @Published var currentEpisode: Episode?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: Double = 0
    @Published var currentTimeString: String = "00:00:00"
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1
    @Published var isSeeking = false
    @Published var isPlaying: Bool = false
    @Published var episodeChapters: [Chapter]? = nil
    @Published var currentChapter: Chapter?
    @Published var currentEpisodeImage: UIImage? = nil
    @Published var currentAudioDeviceName: String? = nil
    @Published var currentEpisodeDescription: AttributedString? = nil
    
    // MARK: - Private Properties
    var player: AVPlayer?
    private var timeObserver: Any?
    private var playlistEpisodes: [Episode] = []
    
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
    
    func getCurrentImageData() {
        guard let currentEpisode = currentEpisode else { return }
                        
        // Get the source data - using chapter if available
        let data = (currentChapter?.imageData ?? currentEpisode.getImageData())
        
        // Convert to UIImage IMMEDIATELY on the Main Thread
        if let data = data {
            // This creates a stable object that survives app switching
            self.currentEpisodeImage = UIImage(data: data)
        }
    }
    
    // Function to handle end of episode procedures
    func handleEpisodeEnd() {
        // Mark episode as listened
        guard let currentEpisode = self.currentEpisode else { return }
        dataManager.markEpisodeAsListened(currentEpisode)
        
        if !playlistEpisodes.isEmpty {
            let nextEpisode = playlistEpisodes.removeFirst()
            startPlayingEpisode(episode: nextEpisode)
        }
    }
    
    // Function to handle the 'playlist' functionality
    func loadEpisodeAndPlaylist(episode: Episode, playlist: [Episode]) {
        if let currentEpisodeIndex = playlist.firstIndex(where: {$0.objectID == episode.objectID}) {
            // stores shrunken array of episodes to be played
            let indexWithoutEpisode = currentEpisodeIndex + 1
            playlistEpisodes = Array(playlist[indexWithoutEpisode...])
        }
        startPlayingEpisode(episode: episode)
    }
    
    func startPlayingEpisode(episode: Episode) {
        self.cleanupPlayer()
        
        var urlToPlay: URL? = nil
        
        if let localPath = downloadManager.getFullDownloadPath(for: episode),
           downloadManager.downloadFileExists(for: episode) {
            urlToPlay = localPath
        } else if let remoteURLString = episode.enclosureUrl,
                 let remoteURL = URL(string: remoteURLString) {
            urlToPlay = remoteURL
        } else {
            return
        }
        
        guard let finalUrl = urlToPlay else {
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
        self.currentEpisodeDescription = self.parseHTML(html: currentEpisode?.episodeDescription)
        
        if episode.chapters != nil {
            let chapters = (episode.chapters as? Set<Chapter>)?
                .sorted { $0.startTime < $1.startTime }
            self.episodeChapters = chapters
        }
        
        // Image data needs to be called after everything has been set up
        getCurrentImageData()
        
        setupNowPlayingInfo()
    }
    
    // Handles the destruction of player object
    func cleanupPlayer() {
        player?.pause()
        isPlaying = false
        currentTime = 0.0
        stopProgressUpdates()
        player = nil
        currentEpisodeImage = nil
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
        if !self.isPlaying {
            self.isPlaying = true
        }
    }
    
    private func getCurrentChapter(time: Int16) -> Chapter? {
        guard let chaps = episodeChapters, !chaps.isEmpty else { return nil }

        // 1. Find the index where the start time is GREATER than the current time.
        // This is the index of the *next* chapter.
        let nextChapterIndex = chaps.firstIndex { $0.startTime > time }
        
        // Checking if the time is in the array. If not, its the last item
        let currentChapterIndex: Int
        if let nextIndex = nextChapterIndex {
            currentChapterIndex = nextIndex - 1
        } else {
            currentChapterIndex = chaps.count - 1
        }
        
        // Playback time is before first chapter time
        guard currentChapterIndex >= 0 else {
            return nil
        }
        
        return chaps[currentChapterIndex]
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
                
                // Check for chapters updates
                if self?.episodeChapters != nil {
                    let potentialNewChapter = self?.getCurrentChapter(time: Int16(time.seconds))
                    if potentialNewChapter != self?.currentChapter {
                        self?.currentChapter = potentialNewChapter
                        // Important to call after new chapter has been set up
                        self?.getCurrentImageData()
                    }
                }
                
                guard let saveFrequency = self?.saveFrequency, let currentEpisode = self?.currentEpisode else { return }
                if time.seconds - currentEpisode.lastListened > saveFrequency {
                    self?.dataManager.saveEpisodeTime(currentEpisode, time: time.seconds)
                }
                
                if let audioOutput = AVAudioSession.sharedInstance().currentRoute.outputs.first {
                    if audioOutput.portType == .builtInSpeaker {
                        self?.currentAudioDeviceName = nil
                    } else if audioOutput.portName != self?.currentAudioDeviceName {
                        self?.currentAudioDeviceName = audioOutput.portName
                    }
                }
                
                // Look for end of episode and handle appropriately
                if currentEpisode.duration - Int16(time.seconds) < 1 {
                    self?.handleEpisodeEnd()
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
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.podcast?.title
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = episode.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
            
        if let image = self.currentEpisodeImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
