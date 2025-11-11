//
//  BackgroundFetch.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/13/25.
//

import Foundation
import BackgroundTasks
    
func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "backgroundRefresh")
    try? BGTaskScheduler.shared.submit(request)
}


