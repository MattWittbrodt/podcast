//
//  MockRepositories.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/8/26.
//

import Foundation

#if DEBUG

extension EpisodeRepository {
    static var preview: EpisodeRepositoryProtocol {
        EpisodeRepository(
            context: PersistenceController.preview.backgroundContext,
            downloadManager: DownloadManager(),
            viewContext: PersistenceController.preview.container.viewContext
        )
    }
}

extension PodcastRepository {
    static var preview: PodcastRepository {
        PodcastRepository(
            context: PersistenceController.preview.backgroundContext,
            viewContext: PersistenceController.preview.container.viewContext
        )
    }
}

extension SettingsRepository {
    static var preview: SettingsRepository {
        SettingsRepository(context: PersistenceController.preview.backgroundContext)
    }
}

extension BookmarkRepository {
    static var preview: BookmarkRepositoryProtocol {
        BookmarkRepository(context: PersistenceController.preview.backgroundContext)
    }
}

#endif
