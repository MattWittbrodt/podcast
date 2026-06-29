//
//  PersistenceManagerDebug.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import CoreData

extension PersistenceController {
    
    func printCoreDataLocation(container: NSPersistentContainer) {
        // Check if stores have been loaded
        guard let store = container.persistentStoreCoordinator.persistentStores.first else {
            print("🔴 Persistent store has not been loaded yet.")
            return
        }
        
        // The 'url' property holds the path to the SQLite file
        if let url = store.url {
            print("✅ Core Data SQLite File Location:")
            print(url.path)
        } else {
            print("🟡 Store URL not found (possibly an in-memory store).")
        }
    }
}
