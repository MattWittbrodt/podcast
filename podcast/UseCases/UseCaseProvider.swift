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
    let episodeRepository: EpisodeRepository
    private let settingsRepository: SettingsRepository
    private let downloadManager: DownloadManager
    private let feedService = PodcastFeedService()
    private let imageService = ImageService()
    private let playbackManager: PlaybackManager

    init(
        podcastRepository: PodcastRepository,
        downloadManager: DownloadManager,
        episodeRepository: EpisodeRepository,
        settingsRepository: SettingsRepository,
        playbackManager: PlaybackManager
    ) {
        self.podcastRepository = podcastRepository
        self.downloadManager = downloadManager
        self.episodeRepository = episodeRepository
        self.settingsRepository = settingsRepository
        self.playbackManager = playbackManager
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
    
    func makeProcessManualDownloadUseCase() -> ProcessManualDownloadUseCase {
        return ProcessManualDownloadUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
        )
    }
    
    func makeFinishEpisodeUseCase() -> FinishEpisodeUseCase {
        return FinishEpisodeUseCase(
            playbackManager: playbackManager,
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
        )
    }
    
    func makeSubscribeToPodcastUseCase() -> SubscribeToPodcastUseCase {
        return SubscribeToPodcastUseCase(
            podcastRepository: podcastRepository,
            episodeRepository: episodeRepository,
            downloadManager: downloadManager
        )
    }
    
    func makeManageSettingsUseCase() -> ManageSettingsUseCase {
        return ManageSettingsUseCase(
            repository: settingsRepository
        )
    }
}
