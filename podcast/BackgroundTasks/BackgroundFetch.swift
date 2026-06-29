//
//  BackgroundFetch.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/13/25.
//

import BackgroundTasks
import UIKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    // Use the exact identifier from your Info.plist
    private let taskIdentifier = "com.planecast.refreshLibrary"
    
    // Inject or access your Use Case
    var refreshLibraryUseCase: RefreshLibraryUseCase?

    private init() {}

    // Call this inside your AppDelegate or @main App init
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: appRefreshTask)
        }
    }

    // Schedule the NEXT background fetch window
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        
        // Request execution in next 60 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 20)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Successfully scheduled background refresh.")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // 1. Schedule the NEXT refresh immediately so the loop continues
        scheduleAppRefresh()

        // 2. Set up a expiration handler in case iOS cuts you off early
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // 3. Execute your Use Case asynchronously
        Task {
            if let useCase = refreshLibraryUseCase {
                print("Exectuing use case")
                await useCase.execute(notifyUser: true)
                task.setTaskCompleted(success: true)
            } else {
                task.setTaskCompleted(success: false)
            }
        }
    }
}

