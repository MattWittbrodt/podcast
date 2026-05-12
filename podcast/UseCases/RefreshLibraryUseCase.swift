//
//  RefreshLibraryUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation

//struct RefreshLibraryUseCase {
//    let feedService: PodcastFeedService
//    let dataManager: DataManager
//    let downloadManager: DownloadManager
//    let settings: SettingsManager
//
//    func execute() async {
//        let newEpisodes = await feedService.updateAllSubscribedPodcasts()
//        await dataManager.updateEpisodesWithChapters()
//        await dataManager.handleNewEpisodes(episodes: newEpisodes)
//
//        // The logic for what to download and what to delete lives here
//        let possibleDownloads = await calculateDownloads(newEpisodes: newEpisodes)
//        
//        for episode in newEpisodes + possibleDownloads {
//            downloadManager.startDownload(for: episode)
//        }
//        
//        for episode in await dataManager.unlistenedEpisodes {
//            if !possibleDownloads.contains(episode) && !episode.manualDownload {
//                downloadManager.removeDownload(for: episode)
//            }
//        }
//    }
//
//    @MainActor private func calculateDownloads(newEpisodes: [Episode]) -> [Episode] {
//        let grouped = Dictionary(grouping: dataManager.unlistenedEpisodes, by: { $0.podcast?.title ?? "Unknown" })
//        return grouped.mapValues { episodes in
//            episodes.sorted { $0.publishedDate ?? .distantPast > $1.publishedDate ?? .distantPast }
//                    .prefix(Int(settings.numDownloads))
//        }.values.flatMap { $0 }
//    }
//}


struct RefreshLibraryUseCase {
    let syncUseCase: SyncPodcastUseCase
    let manageDownloadsUseCase: ManageDownloadsUseCase
    let updateChaptersUseCase: UpdateChaptersUseCase
    let downloadManager: DownloadManager
    let repository: PodcastRepository

    func execute() async {
        let podcastIDs = await MainActor.run {
            return repository.getAllSubscribedPodcasts().map { $0.objectID }
        }

        // Syncing the basic episode information
        await withTaskGroup(of: Void.self) { group in
            for id in podcastIDs {
                group.addTask {
                    await syncUseCase.execute(for: id)
                }
            }
        }
        
        // Update chapters
        await updateChaptersUseCase.execute()
        
        // Start downloads
        await manageDownloadsUseCase.execute()

    }
}
