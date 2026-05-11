//
//  UseCaseProvider.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation

@Observable
class UseCaseProvider {
    private let podcastRepository: PodcastRepository
    private let episodeRepository: EpisodeRepository
    private let downloadManager: DownloadManager
    private let feedService = PodcastFeedService()
    private let imageService = ImageService()

    init(
        podcastRepository: PodcastRepository,
        downloadManager: DownloadManager,
        episodeRepository: EpisodeRepository
    ) {
        self.podcastRepository = podcastRepository
        self.downloadManager = downloadManager
        self.episodeRepository = episodeRepository
    }

    func makeSyncPodcastUseCase() -> SyncPodcastUseCase {
        return SyncPodcastUseCase(
            feedService: feedService,
            imageService: imageService,
            repository: podcastRepository
        )
    }
    
    func makeManageDownloadsUseCase() -> ManageDownloadsUseCase {
        return ManageDownloadsUseCase(
            repository: episodeRepository,
            downloadManager: downloadManager
        )
    }
    
    func makeUpdateChaptersUseCase() -> UpdateChaptersUseCase {
        return UpdateChaptersUseCase(repository: episodeRepository)
    }
    
    func makeRefreshLibraryUseCase() -> RefreshLibraryUseCase {
        return RefreshLibraryUseCase(
            syncUseCase: makeSyncPodcastUseCase(),
            manageDownloadsUseCase: makeManageDownloadsUseCase(),
            updateChaptersUseCase: makeUpdateChaptersUseCase(),
            downloadManager: downloadManager,
            repository: podcastRepository,
        )
    }
}
