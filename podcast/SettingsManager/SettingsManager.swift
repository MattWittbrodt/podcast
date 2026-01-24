//
//  SettingsManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 1/17/26.
//

import Foundation

@MainActor
class SettingsManager: ObservableObject {
    private var dataManager: DataManager
    private var downloadManager: DownloadManager
    @Published var settings: UserSettings
    
    init(downloadManager: DownloadManager, dataManager: DataManager) {
        self.downloadManager = downloadManager
        self.dataManager = dataManager
        let settings = dataManager.getSettings()
        self.settings = settings
    }
    
    // Uses a computed property to update what is displayed
    var numDownloads: Int16 {
        get { settings.downloadCount }
        set {
            objectWillChange.send()
            settings.downloadCount = newValue
            try? dataManager.persistence.viewContext.save()
        }
    }
}

// MARK: Public API
extension SettingsManager {
    
    func deleteDownloads() async throws {
        try await downloadManager.deleteMp3Files()
        await MainActor.run {
            dataManager.refreshEpisodes()
        }
    }
}
