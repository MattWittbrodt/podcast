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
    @Published var skipOptions: [Int16] = [5,10,15,30,45,60,75,90]
    @Published var settings: UserSettings
    
    init(dataManager: DataManager) {
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
    
    var forwardSkip: Int16 {
        get { settings.forwardSkip }
        set {
            objectWillChange.send()
            settings.forwardSkip = newValue
            try! dataManager.persistence.viewContext.save()
        }
    }
    
    var backwardSkip: Int16 {
        get { settings.backwardSkip }
        set {
            objectWillChange.send()
            settings.backwardSkip = newValue
            try! dataManager.persistence.viewContext.save()
        }
    }
    
    var allowCellularDownloads: Bool {
        get { settings.allowCellularDownloads }
        set {
            objectWillChange.send()
            settings.allowCellularDownloads = newValue
            try! dataManager.persistence.viewContext.save()
        }
    }
}

// MARK: Public API
extension SettingsManager {

}
