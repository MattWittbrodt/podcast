//
//  PodcastApp.swift
//  podcast
//
//  Created by Matt app on 3/31/25.
//

import SwiftUI
import AVFoundation
//import Firebase

struct ContentViewFactory {
    @MainActor static func makeContentView(persistence: PersistenceManager = PersistenceManager()) -> ContentView {
        // 1. Create the base dependency
        let dataManager = DataManager(persistence: persistence)
        
        // 2. Create the dependent object using the fully initialized dataManager
        let discoveryManager = DiscoveryManager(dataManager: dataManager)
        
        // 3. Return the fully initialized ContentView
        return ContentView(discoveryManager: discoveryManager, dataManager: dataManager)
    }
}


@main
struct PodcastApp: App {
    @StateObject private var persistenceManager = PersistenceManager()
    @StateObject private var playerManager = PlayerViewModel()
    
    init() {
        //setupAudioInterruptionObserver(with: playerManager)f
        //FirebaseApp.configure()
        setupSharedDirectory()
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.SQLDebug")
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.ConcurrencyDebug")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewFactory.makeContentView()
                .environmentObject(playerManager)
                .environmentObject(persistenceManager)
                .onAppear {
                    // Set up audio session
                    do {
                        playerManager.setupPersistenceManager(persistenceManager)
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        print("Failed to set up audio session: \(error.localizedDescription)")
                    }
                }
        }
    }
}
