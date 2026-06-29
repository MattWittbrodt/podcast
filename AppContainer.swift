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
    let dataManager: DataManager
    let downloadManager: DownloadManager
    let settingsRepository: SettingsRepository
    let episodeRepository: EpisodeRepository
    let podcastRepository: PodcastRepository
    let playbackManager: PlaybackManager
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
    let playerViewModel: PlayerViewModel
    let discoveryManager: DiscoveryManager
    
    @MainActor
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.backgroundContext
        
        // MARK: Manager
        self.dataManager = DataManager(persistence: persistenceController)
        self.downloadManager = DownloadManager()
        
        // MARK: - Repositories
        self.settingsRepository = SettingsRepository(
            dataManager: dataManager,
            context: backgroundContext
        )
        
        self.episodeRepository = EpisodeRepository(
            dataManager: dataManager,
            context: backgroundContext,
            downloadManager: downloadManager
        )
        
        self.podcastRepository = PodcastRepository(
            dataManager: dataManager, context: backgroundContext
        )
        
        // MARK: Playback Manager
        self.playbackManager = PlaybackManager(dataManager: dataManager, settingsRepository: settingsRepository)
        
        // MARK: - Use Cases
        self.playbackUseCase = PlaybackUseCase(
            playbackManager: playbackManager,
            downloadManager: downloadManager,
            episodeRepository: episodeRepository
        )
        
        self.loadEpisodeUseCase = LoadEpisodeUseCase(
            episodeRepo: episodeRepository,
            playbackUseCase: playbackUseCase,
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
            downloadManager: downloadManager,
            repository: podcastRepository,
        )
        
        self.processManualDownloadUseCase = ProcessManualDownloadUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
        )
        
        self.setEpisodeAsListenedUseCase = SetEpisodeAsListenedUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository
        )
        
        self.subscribeToPodcastUseCase = SubscribeToPodcastUseCase(
            podcastRepository: podcastRepository,
            episodeRepository: episodeRepository,
            downloadManager: downloadManager
        )
        
        self.manageSettingsUseCase = ManageSettingsUseCase(repository: settingsRepository)
        
        // MARK: - ViewModels
        self.playerViewModel = PlayerViewModel(
            useCase: manageSettingsUseCase,
            pocastRepository: podcastRepository,
            playbackManager: playbackManager,
            episodeRepository: episodeRepository,
            loadEpisodeUseCase: loadEpisodeUseCase,
            setEpisodeAsListenedUseCase: setEpisodeAsListenedUseCase
        )
        
        self.discoveryManager = DiscoveryManager(dataManager: dataManager)
        
        BackgroundTaskManager.shared.refreshLibraryUseCase = refreshLibraryUseCase
    }
}
