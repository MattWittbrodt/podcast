//
//  PlaybackSyncService.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/16/26.
//

import Foundation

// A clean, dedicated Service layer component
class PlaybackSyncService {
    private let playbackManager: PlaybackManager
    private let repository: EpisodeRepository
    
    init(playbackManager: PlaybackManager, repository: EpisodeRepository) {
        self.playbackManager = playbackManager
        self.repository = repository
    }
    
    private func syncTime(episode: EpisodeRecord, time: TimeInterval) {
        Task {
            await repository.updateLastListened(for: episode.objectId, time: time)
        }
    }
}
