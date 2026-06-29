//
//  NotifcationManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/28/26.
//

import UserNotifications

func sendNotification(message: String, title: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request)
}

func requestNotificationPermissions() {
    let center = UNUserNotificationCenter.current()
    
    // Request permission for alerts and sounds
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("✅ Notification permissions granted!")
        } else if let error = error {
            print("❌ Notification permission error: \(error.localizedDescription)")
        } else {
            print("🚫 User denied notification permissions.")
        }
    }
}
