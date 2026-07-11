//
//  StartPlayingEpisodeUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/1/26.
//

import Foundation
import CoreData

enum PlaybackError: Error {
    case episodeNotFound
    case noAudioUrl
}

struct PlaybackUseCase {
    let playbackManager: PlaybackManager
    let episodeRepository: EpisodeRepository
    let settingsRepository: SettingsRepository
    let podcastRepository: PodcastRepository
    
    func play(episode: EpisodeRecord) {
        playbackManager.startPlayback(
            episode: episode,
            forwardSkip: Int64(settingsRepository.settings.forwardSkip),
            backwardSkip: Int64(settingsRepository.settings.backwardSkip)
        )
    }
    
    func updateRate(_ rate: Float, for episode: EpisodeRecord) {
        playbackManager.updatePlaybackRate(rate)
        podcastRepository.updatePodcastRate(episode.objectId, rate: rate)
    }
    
    func updateLastListened(for episode: EpisodeRecord, at time: TimeInterval) async {
        await episodeRepository.updateLastListened(for: episode.objectId, time: time)
    }
}
