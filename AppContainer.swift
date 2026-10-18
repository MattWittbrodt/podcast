//
//  AppContainer.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/21/26.
//

import Foundation
import CoreData

@Observable
final class AppContainer {
    
    let persistenceController: PersistenceController
    let backgroundContext: NSManagedObjectContext
    let downloadManager: DownloadManager
    // Repositories
    let settingsRepository: SettingsRepository
    let episodeRepository: EpisodeRepository
    let podcastRepository: PodcastRepository
    let bookmarkRepository: BookmarkRepository
    // Managers
    let playbackManager: PlaybackManager
    let bookmarkPlaybackManager: BookmarkPlaybackManager
    // Use Cases
    let loadEpisodeUseCase: LoadEpisodeUseCase
    let playbackUseCase: PlaybackUseCase
    let syncPodcastUseCase: SyncPodcastUseCase
    let manageDownloadsUseCase: ManageDownloadsUseCase
    let updateChaptersUseCase: UpdateChaptersUseCase
    let refreshLibraryUseCase: RefreshLibraryUseCase
    let processManualDownloadUseCase: ProcessManualDownloadUseCase
    let setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase
    let subscribeToPodcastUseCase: SubscribeToPodcastUseCase
    let manageSettingsUseCase: ManageSettingsUseCase
    let manageBookmarksUseCase: ManageBookmarksUseCase
    let createBookmarkClipUseCase: CreateBookmarkClipUseCase
    // View Models
    let playerViewModel: PlayerViewModel
    let recentEpisodesViewModel: RecentEpisodesViewModel
    let discoveryManager: DiscoveryManager
    let bookmarksViewModel: BookmarksViewModel
    let podcastListViewModel: PodcastListViewModel
    
    @MainActor
    init(persistenceController: PersistenceController = .shared) {
        
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.backgroundContext
        
        // MARK: Manager
        self.downloadManager = DownloadManager()
        
        // MARK: - Repositories
        self.settingsRepository = SettingsRepository(context: backgroundContext)
        
        self.episodeRepository = EpisodeRepository(
            context: backgroundContext,
            downloadManager: downloadManager,
            viewContext: persistenceController.container.viewContext
        )
        
        self.podcastRepository = PodcastRepository(
            context: backgroundContext,
            viewContext: persistenceController.container.viewContext
        )
        
        self.bookmarkRepository = BookmarkRepository(context: backgroundContext)
        
        // MARK: Playback Managers
        self.playbackManager = PlaybackManager()
        self.bookmarkPlaybackManager = BookmarkPlaybackManager(playbackManager: playbackManager)
        
        // MARK: - Use Cases
        self.playbackUseCase = PlaybackUseCase(
            playbackManager: playbackManager,
            episodeRepository: episodeRepository,
            settingsRepository: settingsRepository,
            podcastRepository: podcastRepository
        )
        
        self.loadEpisodeUseCase = LoadEpisodeUseCase(
            episodeRepo: episodeRepository,
            playbackUseCase: playbackUseCase
        )
        
        self.syncPodcastUseCase = SyncPodcastUseCase(
            feedService: PodcastFeedService(),
            imageService: ImageService(),
            repository: podcastRepository
        )
        
        self.manageDownloadsUseCase = ManageDownloadsUseCase(
            repository: episodeRepository,
            downloadManager: downloadManager
        )
        
        self.updateChaptersUseCase = UpdateChaptersUseCase(repository: episodeRepository)
        
        self.refreshLibraryUseCase = RefreshLibraryUseCase(
            syncUseCase: syncPodcastUseCase,
            manageDownloadsUseCase: manageDownloadsUseCase,
            updateChaptersUseCase: updateChaptersUseCase,
            repository: podcastRepository,
        )
        
        self.processManualDownloadUseCase = ProcessManualDownloadUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
        )
        
        self.createBookmarkClipUseCase = CreateBookmarkClipUseCase(
            bookmarkRepository: bookmarkRepository,
            filePathService: FilePathService()
        )
        
        self.setEpisodeAsListenedUseCase = SetEpisodeAsListenedUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
            bookmarkRepository: bookmarkRepository,
            createBookmarkClipUseCase: createBookmarkClipUseCase
        )
        
        self.subscribeToPodcastUseCase = SubscribeToPodcastUseCase(
            podcastRepository: podcastRepository,
            episodeRepository: episodeRepository,
            downloadManager: downloadManager
        )
        
        self.manageSettingsUseCase = ManageSettingsUseCase(repository: settingsRepository)
        
        self.manageBookmarksUseCase = ManageBookmarksUseCase(bookmarkRepository: bookmarkRepository)
        
        // MARK: - ViewModels
        self.playerViewModel = PlayerViewModel(
            useCase: manageSettingsUseCase,
            playbackManager: playbackManager,
            loadEpisodeUseCase: loadEpisodeUseCase,
            setEpisodeAsListenedUseCase: setEpisodeAsListenedUseCase,
            playbackUseCase: playbackUseCase
        )
        
        self.recentEpisodesViewModel = RecentEpisodesViewModel(
            refreshLibraryUseCase: refreshLibraryUseCase,
            processManualDownloadUseCase: processManualDownloadUseCase,
            setEpisodeAsListenedUseCase: setEpisodeAsListenedUseCase,
            playerViewModel: playerViewModel,
            loadEpisodesUseCase: loadEpisodeUseCase,
            manageDownloadsUseCase: manageDownloadsUseCase
        )
        
        self.bookmarksViewModel = BookmarksViewModel(
            manageBookmarksUseCase: manageBookmarksUseCase,
            bookmarkPlaybackManager: bookmarkPlaybackManager
        )
        
        self.podcastListViewModel = PodcastListViewModel(
            podcastRepository: podcastRepository,
            subscribeToPodcastUseCase: subscribeToPodcastUseCase,
            manageDownloadsUseCase: manageDownloadsUseCase
        )
        
        // Allows the observe changes for recent episodes to start observing with the coordinator
        // all repositories use
        recentEpisodesViewModel.observeChanges(coordinator: persistenceController.container.persistentStoreCoordinator)
        
        self.discoveryManager = DiscoveryManager()
        
        BackgroundTaskManager.shared.refreshLibraryUseCase = refreshLibraryUseCase
    }
}
