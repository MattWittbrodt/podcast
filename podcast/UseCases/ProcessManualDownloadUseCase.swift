//
//  ManualDownloadUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/14/26.
//

import Foundation

struct ProcessManualDownloadUseCase {
    let downloadManager: DownloadManager
    let episodeRepository: EpisodeRepository

    func execute(for episode: EpisodeRecord, manualOverride: Bool = false) {
        // 1. Business Logic: Start the actual file transfer
        downloadManager.startDownload(for: episode, manualOverride: manualOverride)
        
        // 2. Business Logic: Update the 'Truth' in the database
        Task {
            await episodeRepository.markAsManuallyDownloaded(episode.objectId)
        }
    }
}
