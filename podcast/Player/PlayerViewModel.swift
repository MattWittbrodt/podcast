//
//  PlayerViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/25/25.
//

import Foundation
import AVKit
import CoreData
import MediaPlayer
import Combine

enum PlayerState {
    case stopped, playing, paused
}

@MainActor
protocol PlayerViewModelProtocol: ObservableObject {
    var currentEpisode: Episode? { get }
    //var nextEpisode: Episode? { get }
    var episodeImageData: Data? { get }
    var episodeImageDataPublisher: AnyPublisher<Data?, Never> {get}
    var playerState: PlayerState { get }
    var showFullPlayer: Bool { get set }
    var duration: Int16 { get }
    var currentTime: CMTime { get set }
    var currentTimePublisher: AnyPublisher<CMTime, Never> { get }
    var playbackRate: Float {get set}
    var message: String {get}
    var chapters: [Chapter]? {get}
    var currentChapter: Chapter? {get}
    //var context: NSManagedObjectContext {get}
    
    func seek(seconds: Int64)
    func playPause(alwaysPlay: Bool)
    func skipForward(seconds: Int64)
    func skipBackward(seconds: Int64)
    func updateRate(_ newRate: Float)
    func setupPlayer(episode: Episode) async
    func cleanupPlayer()
    func updatePlaybackRate(_ rate: Float)
    func saveBookmark()
    
    var objectWillChange: ObservableObjectPublisher { get }
}

extension PlayerViewModelProtocol {
    func playPause(alwaysPlay: Bool = false) {
        playPause(alwaysPlay: alwaysPlay)
    }
    
    func playPause() {
        playPause(alwaysPlay: false)
    }
}

@MainActor
final class PlayerViewModel: NSObject, PlayerViewModelProtocol, ObservableObject {
    @Published var message: String = ""
    
    @Published var playerState: PlayerState = .stopped
    @Published var duration: Int16 = 0
    @Published var currentTime = CMTime(value: 0, timescale: 1)
    
    @Published var currentEpisode: Episode? {
        willSet { objectWillChange.send() }
    }
        
    @Published var episodeImageData: Data?
    
    @Published var showFullPlayer = false {
        willSet { objectWillChange.send() }
    }

    @Published var playbackRate: Float = 1.0
    
    private var _chapters: [Chapter]?
    var chapters: [Chapter]? {
        return _chapters
    }
    
    @Published var currentChapter: Chapter?
    
    var currentTimePublisher: AnyPublisher<CMTime, Never> {
        $currentTime.eraseToAnyPublisher()
    }
    
    var playbackRatePublisher: AnyPublisher<Float, Never> {
        $playbackRate.eraseToAnyPublisher()
    }
    
    var episodeImageDataPublisher: AnyPublisher<Data?, Never> {
        $episodeImageData.eraseToAnyPublisher()
    }
    
    private var dispatchTimer: DispatchSourceTimer?
    private var progressUpdateTask: Task<Void, Never>?
    
    private var player: AVPlayer?
    //var context: NSManagedObjectContext
    var saveFrequency: Double = 5
    var lastSaved: Double = 0
    private var playerItemObserver: NSKeyValueObservation?
    
    private weak var context: NSManagedObjectContext?
    
    override init() {
        super.init()
        setupAudioInterruptionObserver()
    }
    
    func setupPersistenceManager(_ manager: PersistenceManager) {
        self.context = manager.viewContext
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
        
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
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
    
    private func setupAudioInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            print("Interrupt: \(notification)")
            // Handle audio interruptions here
            Task{@MainActor in
                print("Interruption Observer PlayPause: \(self.playerState)")
                self.playPause()
            }
        }
    }
    
    private func getCurrentChapter(time: Int16) -> Chapter? {
        guard let chaps = chapters else { return nil}
        return chaps.sorted {$0.startTime < $1.startTime}.last(where: { $0.startTime <= time })
    }
    
    private func getCurrentImage() -> Data? {
        return
            self.currentChapter?.imageData ??
            self.currentEpisode?.imageData ??
            self.currentEpisode?.podcast?.imageData
    }
    
    @MainActor
    private func startProgressUpdates() {
        progressUpdateTask?.cancel()
        
        progressUpdateTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                guard let player = self.player else {break}
                let time = player.currentTime()
                
                await MainActor.run {
                    self.handleProgressUpdate(time: time)
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    @MainActor
    private func handleProgressUpdate(time: CMTime) {
        guard let currentEpisode = self.currentEpisode else { return }
        guard let context = self.context else { return }
        
        let seconds = time.seconds
        
        self.currentTime = time
        
        if seconds.truncatingRemainder(dividingBy: self.saveFrequency) < 1 {
            currentEpisode.lastListened = seconds
            
            // Mark as read
            if currentEpisode.duration - Int16(seconds) < 30 {
                self.currentEpisode?.listened = true
            }
            
            do {
                try context.save()
                self.lastSaved = seconds
            } catch {
                print("Data saved fail: \(error)")
            }
        }
        
        if self.chapters != nil,
           let currentChapter = self.getCurrentChapter(time: Int16(seconds)) {
            if self.currentChapter?.title != currentChapter.title {
                self.currentChapter = currentChapter
                self.episodeImageData = self.getCurrentImage()
            }
        }
        
        self.updateNowPlayingInfo()
    }
    
    private func setInitialImageData() async {
        if let imgData = self.episodeImageData {
            await MainActor.run {
                self.episodeImageData = imgData
            }
        } else if let imgData = self.currentEpisode?.podcast?.imageData {
            await MainActor.run {
                self.episodeImageData = imgData
            }
        } else if let imageURL = self.currentEpisode?.imageUrl {
            do {
                let imgupdate = try await loadImageFromWeb(url: imageURL)
                await MainActor.run {
                    self.episodeImageData = imgupdate
                }
            } catch {
                print("error getting image")
            }
        }
    }
    
    @MainActor func setupPlayerBookmark(bookmark: Bookmark) async {
        self.cleanupPlayer()
        await MainActor.run {
            self.duration = 300
            playbackRate = bookmark.bookmarkEpisode?.podcast?.playbackRate ?? 1.0
            let v = downloadDataUtils.getPathToFile(id: bookmark.bookmarkEpisode?.uuid?.uuidString ?? "")
            
            self.player = AVPlayer(url: v)
            if let player = self.player {
                player.seek(to: CMTime(value: Int64(bookmark.startTime), timescale: 1))
                if self.playerState == .playing {
                    player.play()
                    player.rate = playbackRate
                }
                
                player.allowsExternalPlayback = true
                player.preventsDisplaySleepDuringVideoPlayback = true
                player.automaticallyWaitsToMinimizeStalling = true
            }
        }
    }
    
    @MainActor func setupPlayer(episode: Episode) async {
        print("Running setup")
        // First step is to ensure everything is cleaned up
        self.cleanupPlayer()
        
        do {
            let downloadData = try await downloadDataUtils.downloadEpisodetoFile(url: episode.enclosureUrl!, episodeId: episode.downloadId)
//            if episode.downloaded == false {
//                episode.downloaded = true
//            }
            
            // Lazy load chapters
            await loadChapters(for: episode)
            
            await MainActor.run {
                //self.chapters = episode.sortedChapters
                self.currentEpisode = episode
                self.duration = episode.duration
                self.lastSaved = episode.lastListened
                playbackRate = episode.podcast?.playbackRate ?? 1.0
                
                Task {@MainActor in
                    currentChapter = self.getCurrentChapter(time: Int16(episode.lastListened))
                    episodeImageData = self.getCurrentImage()
                }
                
                self.player = AVPlayer(url: downloadData.path)
                if let player = self.player {
                    player.seek(to: CMTime(value: Int64(episode.lastListened), timescale: 1))
                    if self.playerState == .playing {
                        player.play()
                        player.rate = playbackRate
                    }
                    
                    player.allowsExternalPlayback = true
                    player.preventsDisplaySleepDuringVideoPlayback = true
                    player.automaticallyWaitsToMinimizeStalling = true
                }
            }
            self.setupNowPlayingInfo()
            self.startProgressUpdates()
            self.setupRemoteTransportControls()
            
            if self.player != nil {
                UIApplication.shared.beginReceivingRemoteControlEvents()
                guard let imgURL = URL(string: episode.imageUrl ?? "") else { return }
                let (data, _) = try await URLSession.shared.data(from: imgURL)
                self.episodeImageData = data
            }
            
        } catch ChapterError.badChapters {
                print("Error with chapters")
        } catch {
            print("Player setup failed: \(error)")
        }
    }
    
    // This chapter will check for new chapters and load existing
    private func loadChapters(for episode: Episode) async {
        guard _chapters == nil else { return }
        guard let context = self.context else { return }
        guard let chaptersUrl = episode.chaptersUrl else { return }
        
        let fetchRequest: NSFetchRequest<Chapter> = Chapter.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "episode == %@", episode)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        fetchRequest.fetchBatchSize = 20 // Load in batches
        
        do {
            let chapters = try context.fetch(fetchRequest)
            let decoded = try await decodeChapters(urlString: chaptersUrl)
            // If chapter count doesn't match, start processing
            var newChapters: [Chapter] = []
            if chapters.count != decoded.chapters.count {
                // Delete the existing chapters then process new ones
                for chapter in chapters {
                    context.delete(chapter)
                }
                for chapter in decoded.chapters {
                    let mapped = Chapter.fromWeb(chapter: chapter, context: context)
                    var imgData: Data?
                    if let imgUrl = mapped.imageUrl {
                        imgData = try await loadImageFromWeb(url: imgUrl)
                    }
                    mapped.imageData = imgData
                    mapped.episode = episode
                    newChapters.append(mapped)
                }
                try context.save()
                
                await MainActor.run {
                    _chapters = newChapters
                }
            } else {
                await MainActor.run {
                    _chapters = chapters
                }
            }
        } catch {
            print("error creating chapters: \(error)")
            _chapters = []
        }
    }
        
    func playPause(alwaysPlay: Bool = false) {
        guard let player = player else { return }
        print("Playpause: \(self.playerState) - \(self.currentEpisode?.title ?? "No episode")")
        if player.isPlaying && !alwaysPlay {
            player.pause()
            playerState = PlayerState.paused
            updateNowPlayingInfo()
        } else {
            player.play()
            player.rate = playbackRate
            playerState = PlayerState.playing
            updateNowPlayingInfo()
        }
    }
        
    func updateRate(_ newRate: Float) {
        playbackRate = newRate
        if playerState == .playing {
            player?.rate = newRate
        }
    }
    
    func cleanupPlayer() {
        player = nil  // Release resources
        dispatchTimer?.cancel()
        dispatchTimer = nil
        episodeImageData = nil
        
        // Removing chapters if new player
        _chapters = nil
        currentChapter = nil
    }
        
    func skipForward(seconds: Int64 = 30) {
        guard let player = player else { return }
        let newTime = player.currentTime() + CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
        updateNowPlayingInfo()
    }
    
    func skipBackward(seconds: Int64 = 30) {
        guard let player = player else { return }
        let newTime = player.currentTime() - CMTime(value: seconds, timescale: 1)
        player.seek(to: newTime)
        updateNowPlayingInfo()
    }
    
    func seek(seconds: Int64) {
        guard let player = player else { return }
        player.seek(to: CMTime(value: seconds, timescale: 1))
    }
        
    func updateNowPlayingInfo() {
        guard let episode = currentEpisode else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.podcast?.title
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime.seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = episode.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
            
        if let data = self.episodeImageData, let image = UIImage(data: data) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updatePlaybackRate(_ rate: Float) {
        playbackRate = rate
        if let podcast = self.currentEpisode?.podcast {
            podcast.playbackRate = rate
            try? context?.save()
        }
        if playerState == .playing {
            player?.rate = rate
        }
    }
    
    @MainActor
    func saveBookmark() {
        guard let context = self.context else { return }
        let bookmark = Bookmark(startTime: Int64(self.currentTime.seconds), dateTime: Date(), context: context)
        bookmark.bookmarkEpisode = self.currentEpisode
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func setupObservers() {
        playerItemObserver = player?.observe(\.currentItem?.status, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }
            
            switch player.currentItem?.status {
            case .readyToPlay:
                print("Player item is ready to play")
                // Handle UI updates or auto-play here
            case .failed:
                print("Player item failed to load")
                // Handle error state
            case .none, .some(.unknown):
                break
            @unknown default:
                break
            }
        }
    }
    
}
