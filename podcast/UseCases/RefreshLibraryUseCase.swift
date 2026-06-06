//
//  RefreshLibraryUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation


struct RefreshLibraryUseCase {
    let syncUseCase: SyncPodcastUseCase
    let manageDownloadsUseCase: ManageDownloadsUseCase
    let updateChaptersUseCase: UpdateChaptersUseCase
    let downloadManager: DownloadManager
    let repository: PodcastRepository

    func execute(notifyUser: Bool) async {
        let podcastIDs = await MainActor.run {
            return repository.getAllSubscribedPodcasts().map { $0.objectID }
        }

        // Syncing the basic episode information
        await withTaskGroup(of: Void.self) { group in
            for id in podcastIDs {
                group.addTask {
                    await syncUseCase.execute(for: id, notifyUser: notifyUser)
                }
            }
        }
        
        // Update chapters
        await updateChaptersUseCase.execute()
        
        // Start downloads
        await manageDownloadsUseCase.execute()
        
        UserDefaults.standard.set(Date(), forKey: "last_background_refresh_time")

    }
}
