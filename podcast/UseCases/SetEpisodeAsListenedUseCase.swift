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

    func execute(_ episodeId: NSManagedObjectID) async -> EpisodeRecord? {
        guard let episode = await episodeRepository.getEpisode(for: episodeId) else { return nil }
        
        await episodeRepository.markEpisodeAsListened(episodeId)
        downloadManager.removeDownload(for: episode.savedFileName(), id: episodeId)

        // Only start playing next episode if the one marked as played is currently playing
        return try? await episodeRepository.fetchNextEpisode(after: episode.objectID)
//        if episode.objectID == currentPlayingID {
//            do {
//                let nextEpisode = try await episodeRepository.fetchNextEpisode(after: episode.objectID)
//                if let nextEpisode = nextEpisode {
//                    try await playbackUseCase.play(episode: nextEpisode)
//                }
//            } catch {
//                print("Failed to end episode")
//            }
//        }
    }
}
