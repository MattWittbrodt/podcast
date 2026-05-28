//
//  PodcastApp.swift
//  podcast
//
//  Created by Matt app on 3/31/25.
//

import SwiftUI
import AVFoundation
//import Firebase

struct AppDependencies {
    let dataManager: DataManager
    let downloadManager: DownloadManager
    let playbackManager: PlaybackManager
    let discoveryManager: DiscoveryManager
}

struct ContentViewFactory {
    @MainActor static func makeContentView(persistence: PersistenceManager = PersistenceManager()) -> ContentView {
        let downloadManager = DownloadManager()
        
        // 1. Create the base dependency
        let dataManager = DataManager(persistence: persistence, downloadManager: downloadManager)
        
        let podcastRepository = PodcastRepository(dataManager: dataManager, context: dataManager.persistence.viewContext)
        let episodeRepository = EpisodeRepository(dataManager: dataManager, context: dataManager.persistence.viewContext)
        let settingsRepositry = SettingsRepository(dataManager: dataManager, context: dataManager.persistence.viewContext)
        
        // 2. Create the dependent object using the fully initialized dataManager
        let discoveryManager = DiscoveryManager(dataManager: dataManager)
        let podcastFeedService = PodcastFeedService()
        let playbackManager = PlaybackManager(
            downloadManager: downloadManager,
            dataManager: dataManager,
            settingsRepository: settingsRepositry
        )
        
        // 3. Create the UseCaseProvider (The Logic Hub)
        let useCaseProvider = UseCaseProvider(
            podcastRepository: podcastRepository,
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
            settingsRepository: settingsRepositry,
            playbackManager: playbackManager
        )
        
        downloadManager.allowCellularDownloads = { settingsRepositry.settings.allowCellularDownloads }
        
        let appDependencies = AppDependencies(
            dataManager: dataManager,
            downloadManager: downloadManager,
            playbackManager: playbackManager,
            discoveryManager: discoveryManager
        )
        
        // 3. Return the fully initialized ContentView
        return ContentView(
            discoveryManager: discoveryManager,
            downloadManager: downloadManager,
            dataManager: dataManager,
            feedService: podcastFeedService,
            playbackManager: playbackManager,
            useCaseProvider: useCaseProvider,
            appDependencies: appDependencies,
        )
    }
}

@main
struct PodcastApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        //FirebaseApp.configure()
        setupSharedDirectory()
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.SQLDebug")
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.ConcurrencyDebug")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewFactory.makeContentView()
        }
    }
}
