//
//  PodcastApp.swift
//  podcast
//
//  Created by Matt app on 3/31/25.
//

import SwiftUI
import AVFoundation
import BackgroundTasks
//import Firebase


let BACKGROUND_TASK_NAME = "com.mattw.planecast.datafetch"

private func handleTask(task: BGAppRefreshTask) {
    let count = UserDefaults.standard.integer(forKey: "task_run_count")
    UserDefaults.standard.set(count + 1, forKey: "task_run_count")
    task.setTaskCompleted(success: true)
}

private func schedule() {
    BGTaskScheduler.shared.getPendingTaskRequests { requests in
        print("\(requests.count) BG tasks pending")
    }
    // It's generally better to check if an existing task is pending before canceling
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BACKGROUND_TASK_NAME)
    
    // Submit the task to be scheduled
    do {
        let newTask = BGAppRefreshTaskRequest(identifier: BACKGROUND_TASK_NAME)
        newTask.earliestBeginDate = Date(timeIntervalSinceNow: 60*60)
        try BGTaskScheduler.shared.submit(newTask)
        print("Task scheduled")
    } catch {
        print("Error scheduling task: \(error.localizedDescription)") // Print error detail
    }
}

struct ContentViewFactory {
    @MainActor static func makeContentView(persistence: PersistenceManager = PersistenceManager()) -> ContentView {
        // 1. Create the base dependency
        let dataManager = DataManager(persistence: persistence)
        
        // 2. Create the dependent object using the fully initialized dataManager
        let discoveryManager = DiscoveryManager(dataManager: dataManager)
        let downloadManager = DownloadManager(dataManager: dataManager)
        let podcastFeedService = PodcastFeedService(dataManager: dataManager)
        let playbackManager = PlaybackManager(downloadManager: downloadManager, dataManager: dataManager)
        
        // 3. Return the fully initialized ContentView
        return ContentView(
            discoveryManager: discoveryManager,
            downloadManager: downloadManager,
            dataManager: dataManager,
            feedService: podcastFeedService,
            playbackManager: playbackManager
        )
    }
}

@main
struct PodcastApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var playerManager = PlayerViewModel()
    
    // Background task management
    //let taskManager = BackgroundTaskManager()
    @Environment(\.scenePhase) private var phase
    
    init() {
//        tasknew()
//        schedule()
        //setupAudioInterruptionObserver(with: playerManager)
        //FirebaseApp.configure()
        setupSharedDirectory()
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.SQLDebug")
        UserDefaults.standard.set(0, forKey: "com.apple.CoreData.ConcurrencyDebug")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewFactory.makeContentView()
                .environmentObject(playerManager)
                .onAppear {
                    // Set up audio session
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        print("Failed to set up audio session: \(error.localizedDescription)")
                    }
                }
        }
        .onChange(of: phase) { oldPhase, newPhase in
            if newPhase == .background {
                // Schedule the task only when the app goes to the background
                schedule()
            }
        }
//        .onChange(of: phase) { newPhase in
////            if newPhase == .background {
////                taskManager.scheduleAppRefresh()
////            }
//        }
//        .backgroundTask(.appRefresh("com.mattw.planecast.datafetch")) {
//            let dataManager = await DataManager(persistence: PersistenceManager())
//            do {
//                try await dataManager.writeLastLogTime()
//                print("Done")
//            } catch {
//                print("bad: \(error)")
//            }
//        }
    }
}
