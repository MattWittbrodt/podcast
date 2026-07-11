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
    let repository: PodcastRepository

    func execute(notifyUser: Bool) async {
        let podcastIDs = try? await repository.fetchAll().map { $0.objectId }
        
        guard let podcastIDs else { return }

        // Syncing the basic episode information
        await withTaskGroup(of: Void.self) { group in
            for id in podcastIDs {
                group.addTask {
                    await syncUseCase.execute(for: id, notifyUser: notifyUser)
                }
            }
        }
        await updateChaptersUseCase.execute()
        await manageDownloadsUseCase.execute()
        UserDefaults.standard.set(Date(), forKey: "last_background_refresh_time")
    }
}
