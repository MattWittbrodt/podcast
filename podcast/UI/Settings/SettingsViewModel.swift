//
//  SettingsViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/25/26.
//

import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var skipOptions: [Int16] = [5,10,15,30,45,60,75,90]
    @Published var lastUpdateTime: String = "Never"
    
    private let useCase: ManageSettingsUseCase
    
    init(useCase: ManageSettingsUseCase) {
        self.useCase = useCase
    }
    
    // UI binds directly to these computed properties
    var numDownloads: Int16 {
        get { useCase.get(\UserSettings.downloadCount) }
        set {
            objectWillChange.send()
            useCase.execute(\UserSettings.downloadCount, to: newValue)
        }
    }

    var forwardSkip: Int16 {
        get { useCase.get(\UserSettings.forwardSkip) }
        set {
            objectWillChange.send()
            useCase.execute(\UserSettings.forwardSkip, to: newValue)
        }
    }
    
    var backwardSkip: Int16 {
        get { useCase.get(\UserSettings.backwardSkip) }
        set {
            objectWillChange.send()
            useCase.execute(\UserSettings.backwardSkip, to: newValue)
        }
    }
    
    var allowCellularDownloads: Bool {
        get { useCase.get(\UserSettings.allowCellularDownloads) }
        set {
            objectWillChange.send()
            useCase.execute(\UserSettings.allowCellularDownloads, to: newValue)
        }
    }
    
    func getLastUpdateTime() {
        if let lastDate = UserDefaults.standard.object(forKey: "last_background_refresh_time") as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            lastUpdateTime = "Last Data Update: \(formatter.string(from: lastDate))"
        } else {
            lastUpdateTime = "None"
        }
    }
}
