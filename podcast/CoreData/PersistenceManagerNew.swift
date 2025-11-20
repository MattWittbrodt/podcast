//
//  PersistenceManagerNew.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/13/25.
//

import Foundation
import CoreData

final class PersistenceManager: ObservableObject {
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "UserData")
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        
        // Load stores
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
            
            // Configure context
            self?.configureContext()
        }
        printCoreDataLocation(container: self.container)
    }
    
    private func configureContext() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Optional performance optimizations
        viewContext.undoManager = nil
        
    }
    
    // MARK: - Save Methods
    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - Background Operations
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask(block)
    }
    
    // Alternative for completion handler style
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
