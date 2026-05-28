//
//  FinishEpisodeUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/14/26.
//

import Foundation

struct FinishEpisodeUseCase {
    let playbackManager: PlaybackManager
    let downloadManager: DownloadManager
    
    let episodeRepository: EpisodeRepository

    func execute(_ episode: Episode) {
        episodeRepository.markEpisodeAsListened(episode)
        
        // If the user manually finishes the episode they are currently hearing,
        // we need to stop/skip.
        Task {@MainActor in
            if playbackManager.currentEpisode?.objectID == episode.objectID {
                playbackManager.handleEpisodeEnd()
            }
        }
        
        // Remove download to free storage
        downloadManager.removeDownload(for: episode)
    }
}
