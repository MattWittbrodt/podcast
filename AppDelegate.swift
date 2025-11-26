//
//  AppDelegate.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/25/25.
//

import Foundation
import BackgroundTasks
import UIKit

// 1. Create a class that conforms to UIApplicationDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // This method runs ONLY ONCE when the app process is created.
        registerBackgroundTasks()
        
        // Perform other necessary setup here (like Firebase config)
        // FirebaseApp.configure()
        
        return true
    }
    
    // Move your registration logic here
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BACKGROUND_TASK_NAME, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleTask(task: task)
        }
        
        // You can keep your initial print/count logic here too
        let count = UserDefaults.standard.integer(forKey: "task_run_count")
        print("App launched \(count) times")
    }
    
    // Move your handler function here
    private func handleTask(task: BGAppRefreshTask) {
        print("running")
        let count = UserDefaults.standard.integer(forKey: "task_run_count")
        UserDefaults.standard.set(count + 1, forKey: "task_run_count")
        task.setTaskCompleted(success: true)
    }
}
