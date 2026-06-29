//
//  PodcastApp.swift
//  podcast
//
//  Created by Matt app on 3/31/25.
//

import SwiftUI
import AVFoundation

@main
struct PodcastApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @State private var container = AppContainer()
    
    init() {
        setupSharedDirectory()
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.SQLDebug")
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.ConcurrencyDebug")
        BackgroundTaskManager.shared.registerBackgroundTask()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .onAppear {
                    // Ask for permission the first time they open the app
                    requestNotificationPermissions()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                print("New background")
                // 3. Schedule the task as the user leaves the app
                BackgroundTaskManager.shared.scheduleAppRefresh()
            }
        }
    }
}
