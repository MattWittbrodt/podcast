//
//  FinishEpisodeUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/14/26.
//

import Foundation
import CoreData

struct SetEpisodeAsListenedUseCase {
    let downloadManager: DownloadManager
    let episodeRepository: EpisodeRepository
    let startPlayingEpisodeUseCase: StartPlayingEpisodeUseCase
    let playbackManager: PlaybackManager

    func execute(_ episode: Episode) async {
        await episodeRepository.markEpisodeAsListened(episode.objectID)
        downloadManager.removeDownload(for: episode.savedFileName(), id: episode.objectID)
        let currentPlayingID = await MainActor.run { playbackManager.currentEpisode?.objectID }

        // Only start playing next episode if the one marked as played is currently playing
        if episode.objectID == currentPlayingID {
            do {
                let nextEpisode = try await episodeRepository.fetchNextEpisode(after: episode.objectID)
                if let nextEpisode = nextEpisode {
                    try await startPlayingEpisodeUseCase.execute(episodeId: nextEpisode.objectID)
                }
            } catch {
                print("Failed to end episode")
            }
        }
    }
}
