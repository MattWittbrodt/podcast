//
//  ApplyDownloadPolicyUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation

struct ManageDownloadsUseCase {
    let repository: EpisodeRepositoryProtocol
    let downloadManager: DownloadManager

    func execute() async {
        let episodesToKeep = await repository.getRecentEpisodesForEachPodcast(limit: 3)
        let keepIds = Set(episodesToKeep.map(\.objectId))
        
        // Start auto-downloads
        for episode in episodesToKeep {
            downloadManager.startDownload(for: episode)
            if let actualLength = await downloadManager.getActualFileLength(for: episode), actualLength != episode.duration {
                await repository.updateDurationFromFile(for: episode.objectId, length: actualLength)
            }
        }

        // Cleanup episodes that should not be saved on device
        // ONLY remove if it's NOT in the 'keep' list AND NOT a 'manual' download
        guard let allUnlistened = try? await repository.fetchUnlistened() else { return }
        for episode in allUnlistened {
            if !keepIds.contains(episode.objectId) && !episode.manualDownload {
                downloadManager.removeDownload(for: episode)
            }
        }
    }
    
    func episodeState(episode: EpisodeRecord) -> DownloadState {
        return downloadManager.state(for: episode)
    }
}
