//
//  PlayerViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/26.
//

import Foundation
import Observation
import AVKit
import CoreData

enum PlaybackPhase: Equatable {
    case idle
    case loading
    case playing
    case paused
}

@MainActor
@Observable
final class PlayerViewModel {
    private let useCase: ManageSettingsUseCase
    private let playbackManager: PlaybackManager
    private let loadEpisodeUseCase: LoadEpisodeUseCase
    private let chapterPlaybackUseCase: ChapterPlaybackUseCase = ChapterPlaybackUseCase()
    private let setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase
    private let playbackUseCase: PlaybackUseCaseProtocol
    
    var showFullPlayer: Bool = false
    
    init(
        useCase: ManageSettingsUseCase,
        playbackManager: PlaybackManager,
        loadEpisodeUseCase: LoadEpisodeUseCase,
        setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase,
        playbackUseCase: PlaybackUseCase
    ) {
        self.useCase = useCase
        self.playbackManager = playbackManager
        self.loadEpisodeUseCase = loadEpisodeUseCase
        self.setEpisodeAsListenedUseCase = setEpisodeAsListenedUseCase
        self.playbackUseCase = playbackUseCase
        
        startObservingTime()
    }
    
    // Main variable to grab information from
    var currentEpisode: EpisodeRecord?
    
    // Pass-through properties keep your view ergonomics perfect
    var currentTime: Double {
        get { playbackManager.currentTime }
        set { playbackManager.currentTime = newValue }
    }

    var forwardSkip: Int16 {
        get { useCase.get(\UserSettings.forwardSkip) }
    }
    
    var backwardSkip: Int16 {
        get { useCase.get(\UserSettings.backwardSkip) }
    }
    
    // Control of bar
    var duration: Double { playbackManager.duration }
    
    var currentTimeString: String { formattedTime(time: playbackManager.currentTime) }
    
    var playButtonIcon: String {
        playbackManager.isPlaying ? "pause.fill" : "play.fill"
    }
    
    var audioDeviceName: String? {
        playbackManager.currentAudioDeviceName
    }
    
    var lastListened: TimeInterval = 0
    var phase: PlaybackPhase = .idle
    var playbackRate: Float = 1.0
    var currentEpisodeImage: UIImage? = nil
    var currentEpisodeDescription: AttributedString? = nil
    
    // Episode chapters - need to compute below and cache
    var episodeChapters: [ChapterRecord] = []
    var currentChapter: ChapterRecord?
    
    // User actions to player manager
    func togglePlayPause() { playbackManager.playPause() }
    func skipForward() { playbackManager.skipForward(seconds: Int64(self.forwardSkip)) }
    func skipBackward() { playbackManager.skipBackward(seconds: Int64(self.backwardSkip)) }
    func finishedScrubbing() { playbackManager.seek(to: playbackManager.currentTime) }
    func seek(to time: Double) { playbackManager.seek(to: time)}
    func setIsSeeking(_ seeking: Bool) { playbackManager.isSeeking = seeking }
    
    private func startObservingTime() {
        guard let timeStream = playbackManager.timeStream else { print("No timestream"); return }
        Task {
            for await time in timeStream {
                // If player is not playing, do not do any further checks
                guard phase == .playing else { continue }
                
                currentTime = time
                guard let currentEpisode = currentEpisode else { continue }
                // Triggering a save if the most recent timestamp is >5s away from previous
                if abs(currentTime - lastListened) > 5  {
                    await playbackUseCase.updateLastListened(for: currentEpisode, at: time)
                    lastListened = currentTime
                }
                // Checking for new chapter
                if let transition = await chapterPlaybackUseCase.checkTransition(at: time, in: currentEpisode) {
                    await MainActor.run {
                        currentChapter = transition.chapter
                        // Only swap artwork if chapter has its own, else keep episode art
                        if let chapterArt = transition.artwork {
                            currentEpisodeImage = chapterArt
                            playbackManager.setCurrentEpisodeImage(img: chapterArt)
                        }
                    }
                }
                // Checking if this is now at episode end
                if currentEpisode.duration - Int16(time) < 3, phase == .playing {
                    phase = .loading
                    if let nextEpisode = try? await setEpisodeAsListenedUseCase.execute(currentEpisode) {
                        await selectEpisode(nextEpisode.objectId)
                    }
                }
            }
        }
    }
    
    func selectEpisode(_ episodeId: NSManagedObjectID) async {
        phase = .loading
        chapterPlaybackUseCase.reset()
        currentChapter = nil
        lastListened = 0
        
        guard let loaded = await loadEpisodeUseCase.forPlayback(episodeID: episodeId) else {
            print("Failed to load episode from selectEpisode")
            return
        }
        currentEpisode = loaded.episode
        episodeChapters = loaded.episode.chapters
        
        playbackManager.updatePlaybackRate(loaded.episode.playbackRate)
        playbackRate = loaded.episode.playbackRate
        
        async let description = Task.detached(priority: .background) {
            parseHTML(html: loaded.episode.episodeDescription)
        }.value
        
        let parsedDescription = await description
        currentEpisodeDescription = parsedDescription
        
        guard let data = loaded.artwork else { return }
        if let uiImage = UIImage(data: data) {
            currentEpisodeImage = uiImage
            playbackManager.setCurrentEpisodeImage(img: uiImage)
        }
        phase = .playing
        showFullPlayer = true
    }
    
    func playBookmark(_ bookmark: BookmarkRecord) {
        playbackUseCase.play(bookmark: bookmark)
    }
    
    func updateRate(_ rate: Float) {
        self.playbackRate = rate
        guard let episode = currentEpisode else { return }
        playbackUseCase.updateRate(rate, for: episode)
    }
    
    func getCurrentEpisodeDescription() -> AttributedString? {
        return parseHTML(html: playbackManager.currentEpisode?.episodeDescription)
    }
}
