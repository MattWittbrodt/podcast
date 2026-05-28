//
//  ApplyDownloadPolicyUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation

struct ManageDownloadsUseCase {
    let repository: EpisodeRepository
    let downloadManager: DownloadManager

    func execute() async {
        let episodesToKeep = await repository.getRecentEpisodesForEachPodcast(limit: 3)
        
        // Start auto-downloads
        for episode in episodesToKeep {
            downloadManager.startDownload(for: episode)
            
            if let actualLength = await downloadManager.getActualFileLength(for: episode), actualLength != episode.duration {
                await repository.updateDurationFromFile(for: episode, length: actualLength)
            }
        }

        // Cleanup episodes that should not be saved on device
        // ONLY remove if it's NOT in the 'keep' list AND NOT a 'manual' download
        let allUnlistened = await repository.getAllUnlistenedEpisodes()
        for episode in allUnlistened {
            if !episodesToKeep.contains(episode) && !episode.manualDownload {
                downloadManager.removeDownload(for: episode)
            }
        }
    }
}
