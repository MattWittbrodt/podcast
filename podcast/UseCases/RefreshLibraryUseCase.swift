//
//  RefreshLibraryUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation


actor RefreshLibraryUseCase {
    let syncUseCase: SyncPodcastUseCase
    let manageDownloadsUseCase: ManageDownloadsUseCase
    let updateChaptersUseCase: UpdateChaptersUseCase
    let repository: PodcastRepository
    private var isRefreshing = false
    
    init(
        syncUseCase: SyncPodcastUseCase,
        manageDownloadsUseCase: ManageDownloadsUseCase,
        updateChaptersUseCase: UpdateChaptersUseCase,
        repository: PodcastRepository
    ) {
        self.syncUseCase = syncUseCase
        self.manageDownloadsUseCase = manageDownloadsUseCase
        self.updateChaptersUseCase = updateChaptersUseCase
        self.repository = repository
    }

    func execute(notifyUser: Bool) async {
        guard !isRefreshing else {
            log("Refresh already in progress, skipping")
            return
        }
        isRefreshing = true
        defer {
            isRefreshing = false
            log("RefreshLibraryUseCase finished")
        }
        let podcastIDs = try? await repository.fetchAll().map { $0.objectId }
        guard let podcastIDs else { return }

        // Syncing the basic episode information
        await withTaskGroup(of: Void.self) { group in
            for id in podcastIDs {
                group.addTask {
                    await self.syncUseCase.execute(for: id, notifyUser: notifyUser)
                }
            }
        }
        await updateChaptersUseCase.execute()
        await manageDownloadsUseCase.execute()
        UserDefaults.standard.set(Date(), forKey: "last_background_refresh_time")
    }
}
