//
//  PodcastApp.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/31/25.
//

import SwiftUI
import AVFoundation
import Firebase

@main
struct PodcastApp: App {
    @StateObject private var persistenceManager = PersistenceManager()
    //@StateObject private var playerManager = PlayerViewModel(context: PersistenceManager.viewContext)
    @StateObject private var playerManager = PlayerViewModel()
    
    init() {
        //setupAudioInterruptionObserver(with: playerManager)
        FirebaseApp.configure()
        setupSharedDirectory()
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.SQLDebug")
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.ConcurrencyDebug")
    }
    
//    private func setupAudioInterruptionObserver(with playerManager: PlayerViewModel) {
//        NotificationCenter.default.addObserver(
//            forName: AVAudioSession.interruptionNotification,
//            object: nil,
//            queue: .main
//        ) { notification in
//            print("Interrupt: \(notification)")
//            // Handle audio interruptions here
//            Task{@MainActor in
//                playerManager.playPause()
//            }
//        }
//    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                //.environment(\.managedObjectContext, persistenceController.container.viewContext)
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
