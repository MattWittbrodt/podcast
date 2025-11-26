////
////  BackgroundFetch.swift
////  podcast
////
////  Created by Matt Wittbrodt on 6/13/25.
////
//
//import Foundation
//import BackgroundTasks
//import CoreData
//
//// 1. Define the unique task identifier (MUST match Info.plist entry)
//let BACKGROUND_TASK_IDENTIFIER = "com.mattw.planecast.datafetch"
//
//class BackgroundTaskManager {
//    
//    // Replace this with your actual Core Data container setup
//    private lazy var persistentContainer: NSPersistentContainer = {
//        return PersistenceManager().container
//    }()
//    
//    // MARK: - Task Registration (Call in your App's init or main file)
//    func registerTask() {
//        BGTaskScheduler.shared.register(
//            forTaskWithIdentifier: BACKGROUND_TASK_IDENTIFIER,
//            using: nil // Use default queue
//        ) { task in
//            // When the OS runs the task, this closure is executed
//            self.handleAppRefresh(task: task as! BGAppRefreshTask)
//        }
//        print("Background task registered: \(BACKGROUND_TASK_IDENTIFIER)")
//    }
//    
//    // MARK: - Task Scheduling - 30 min
//    func scheduleAppRefresh() {
//        // Cancel any pending task before scheduling a new one (optional but good practice)
//        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BACKGROUND_TASK_IDENTIFIER)
//        
//        let request = BGAppRefreshTaskRequest(identifier: BACKGROUND_TASK_IDENTIFIER)
//        
//        // Set the earliest time the system can run the task (30 minutes)
//        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60) // 1800 seconds
//        
//        do {
//            try BGTaskScheduler.shared.submit(request)
//            print("Successfully scheduled next app refresh for no sooner than 30 minutes.")
//            self.printPendingTasks()
//        } catch {
//            print("Could not schedule app refresh: \(error)")
//        }
//    }
//    
//    func scheduleAppRefreshBasic() {
//        // ... (cancellation logic remains)
//        
//        let request = BGAppRefreshTaskRequest(identifier: BACKGROUND_TASK_IDENTIFIER)
//
//        // *** REMOVE THE EARLIEST DATE TEMPORARILY ***
//        // request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
//
//        do {
//            try BGTaskScheduler.shared.submit(request)
//            print("Successfully scheduled next app refresh immediately (TEST).")
//            self.printPendingTasks()
//        } catch {
//            print("Could not schedule app refresh: \(error)")
//        }
//    }
//    
//    func printPendingTasks() {
//        BGTaskScheduler.shared.getPendingTaskRequests { requests in
//            if requests.isEmpty {
//                print("DEBUG: No pending background task requests found.")
//            } else {
//                print("DEBUG: Found \(requests.count) pending task request(s):")
//                for request in requests {
//                    print("  - ID: \(request.identifier), Earliest Start: \(String(describing: request.earliestBeginDate))")
//                }
//            }
//        }
//    }
//    
//    // MARK: - Task Execution Handler
//    private func handleAppRefresh(task: BGAppRefreshTask) {
//        // 1. Reschedule the task immediately for the next interval
//        scheduleAppRefresh()
//        
//        // 2. Define a time limit for the task (must finish before expiration)
//        task.expirationHandler = {
//            // Cancel pending operations if the task is about to expire
//            print("Background task expired. Cancelling network operation.")
//            // Implement cancellation logic if needed (e.g., cancel URLSession tasks)
//            task.setTaskCompleted(success: false)
//        }
//        
//        // 3. Start the asynchronous work
//        Task {
//            let persistenceManager = PersistenceManager()
//            let dataManager = await DataManager(persistence: persistenceManager)
//            let feedService = PodcastFeedService(dataManager: dataManager)
//            let downloadManager = DownloadManager(dataManager: dataManager)
//            
//            let newEpisodes = await feedService.updateAllSubscribedPodcasts()
//            await dataManager.updateEpisodesWithChapters()
//            
//            // Continue handling episodes
//            await dataManager.handleNewEpisodes(episodes: newEpisodes)
//            for episode in newEpisodes {
//                downloadManager.startDownload(for: episode)
//            }
//            do {
//                try await dataManager.writeLastLogTime()
//            } catch {
//                print("failed")
//            }
//        }
//        task.setTaskCompleted(success: true)
//    }
//}
//
//// MARK: - Testing in Simulator
//
//// To test background tasks in the Xcode Simulator:
//// 1. Run your app (stop when finished).
//// 2. In the Debug area (bottom of Xcode), use the following lldb command,
////    replacing the identifier with your own:
////    e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.yourapp.datafetch"]
