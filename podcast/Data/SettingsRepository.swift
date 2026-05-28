//
//  SettingsRepository.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/26/26.
//

import CoreData

class SettingsRepository {
    let dataManager: DataManager
    var settings: UserSettings
    private let context: NSManagedObjectContext

    init(dataManager: DataManager, context: NSManagedObjectContext) {
        self.dataManager = dataManager
        self.context = context
        
        // Populate with the most current setting upon load
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSettings.updateTime, ascending: false)]
        request.fetchLimit = 1
        if let settings = try? context.fetch(request).first {
            self.settings = settings
        } else {
            let settings = UserSettings.create(context: context)
            try? context.save()
            self.settings = settings
        }
    }
    
    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Repo Save Error: \(error)")
            context.rollback()
        }
    }
    
    /// Updates any property on the UserSettings object and saves the context.
    /// - Parameters:
    ///   - keyPath: A type-safe reference to a specific property on UserSettings
    ///   - newValue: The new value matching the property's type
    func update<Value>(_ keyPath: WritableKeyPath<UserSettings, Value>, to newValue: Value) {
        // 1. Assign the new value using Swift's subscript KeyPath syntax
        self.settings[keyPath: keyPath] = newValue
        
        // 2. Commit the changes to disk safely
        self.save()
    }
    
    // Expose plain, safe getters
//    var numDownloads: Int16 { settings.downloadCount }
//    var forwardSkip: Int16 { settings.forwardSkip }
//    var backwardSkip: Int16 { settings.backwardSkip }
//    var allowCellularDownloads: Bool { settings.allowCellularDownloads }
}
