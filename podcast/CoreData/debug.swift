//
//  debug.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/11/25.
//

import Foundation
import CoreData

extension PersistenceManager {
    func debugPublishedDateTypes() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            print("🔍 DEBUGGING publishedDate TYPE ISSUE")
            
            // Get metadata from existing store
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL
            )
            
            // Check what the EXISTING store thinks publishedDate should be
            if let storeModel = NSManagedObjectModel.mergedModel(
                from: [Bundle.main],
                forStoreMetadata: metadata
            ) {
                if let episodeEntity = storeModel.entitiesByName["Episode"],
                   let publishedDateAttr = episodeEntity.propertiesByName["publishedDate"] as? NSAttributeDescription {
                    let storeType = publishedDateAttr.attributeType
                    print("📅 EXISTING STORE expects publishedDate type: \(stringFromAttributeType(storeType)) (\(storeType.rawValue))")
                } else {
                    print("❌ EXISTING STORE: No publishedDate attribute found in Episode entity")
                }
            }
            
            // Check what CURRENT model expects
            if let episodeEntity = container.managedObjectModel.entitiesByName["Episode"],
               let publishedDateAttr = episodeEntity.propertiesByName["publishedDate"] as? NSAttributeDescription {
                let currentType = publishedDateAttr.attributeType
                print("📅 CURRENT MODEL wants publishedDate type: \(stringFromAttributeType(currentType)) (\(currentType.rawValue))")
            } else {
                print("❌ CURRENT MODEL: No publishedDate attribute found in Episode entity")
            }
            
            // Print all entities and properties for comparison
            print("\n📊 COMPLETE MODEL COMPARISON:")
            compareModels(metadata: metadata)
            
        } catch {
            print("❌ Debug failed: \(error)")
        }
    }
    
    func comprehensiveCoreDataDebug() {
        print("🔍 COMPREHENSIVE CORE DATA DEBUG")
        
        // 1. Check all data models
        print("\n📦 ALL DATA MODELS:")
        let bundles = Bundle.allBundles + Bundle.allFrameworks
        for bundle in bundles {
            if let modelURLs = bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) {
                for modelURL in modelURLs {
                    print("   - \(modelURL.lastPathComponent)")
                    if let model = NSManagedObjectModel(contentsOf: modelURL) {
                        for (entityName, entity) in model.entitiesByName {
                            print("     └─ Entity: \(entityName) → \(entity.managedObjectClassName)")
                        }
                    }
                }
            }
        }
        
        // 2. Check entity resolutions
        print("\n🔍 ENTITY RESOLUTION:")
        let entities = NSEntityDescription.entity(forEntityName: "Podcast", in: viewContext)
        print("   Podcast entity: \(entities?.managedObjectClassName ?? "nil")")
        
        // 3. Check class existence
        print("\n🏷️ CLASS CHECK:")
        if let podcastClass = NSClassFromString("Podcast") {
            print("   Podcast class exists: \(podcastClass)")
        } else {
            print("   Podcast class not found")
        }
        
        // 4. Check module
        print("\n📱 MODULE INFO:")
        print("   Module name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown")")
    }
    
    func debugDataModels() {
        let bundles = Bundle.allBundles
        for bundle in bundles {
            if let modelURLs = bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) {
                for modelURL in modelURLs {
                    print("📦 Found data model: \(modelURL.lastPathComponent)")
                    
                    if let model = NSManagedObjectModel(contentsOf: modelURL) {
                        for entityName in model.entitiesByName.keys {
                            print("   - Entity: \(entityName)")
                        }
                    }
                }
            }
        }
    }

    private func stringFromAttributeType(_ type: NSAttributeType) -> String {
        switch type {
        case .stringAttributeType: return "String"
        case .integer16AttributeType: return "Int16"
        case .integer32AttributeType: return "Int32"
        case .integer64AttributeType: return "Int64"
        case .decimalAttributeType: return "Decimal"
        case .doubleAttributeType: return "Double"
        case .floatAttributeType: return "Float"
        case .booleanAttributeType: return "Bool"
        case .dateAttributeType: return "Date"
        case .binaryDataAttributeType: return "Binary Data"
        case .UUIDAttributeType: return "UUID"
        case .URIAttributeType: return "URI"
        case .transformableAttributeType: return "Transformable"
        @unknown default: return "Unknown"
        }
    }

    private func compareModels(metadata: [String: Any]) {
        print("--- EXISTING STORE MODEL ---")
        if let storeModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: metadata) {
            for (entityName, entity) in storeModel.entitiesByName {
                print("Entity: \(entityName)")
                for (propertyName, property) in entity.propertiesByName {
                    if let attribute = property as? NSAttributeDescription {
                        print("  - \(propertyName): \(stringFromAttributeType(attribute.attributeType))")
                    } else if let relationship = property as? NSRelationshipDescription {
                        print("  - \(propertyName): Relationship → \(relationship.destinationEntity?.name ?? "unknown")")
                    }
                }
            }
        }
        
        print("\n--- CURRENT MODEL ---")
        for (entityName, entity) in container.managedObjectModel.entitiesByName {
            print("Entity: \(entityName)")
            for (propertyName, property) in entity.propertiesByName {
                if let attribute = property as? NSAttributeDescription {
                    print("  - \(propertyName): \(stringFromAttributeType(attribute.attributeType))")
                } else if let relationship = property as? NSRelationshipDescription {
                    print("  - \(propertyName): Relationship → \(relationship.destinationEntity?.name ?? "unknown")")
                }
            }
        }
    }
        
        func setupCoreData() {
            print("🔍 Setting up Core Data...")
            
            // First, let's see what's actually in the store directory
            inspectStoreDirectory()
            
            // Load with migration enabled
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
            
            container.loadPersistentStores { [weak self] (storeDescription, error) in
                if let error = error as NSError? {
                    print("❌ Core Data load failed: \(error)")
                    
                    if error.code == 134140 {
                        print("🔄 Store corruption detected - performing reset...")
                        self?.completelyResetCoreData()
                    }
                } else {
                    print("✅ Core Data loaded successfully!")
                    self?.configureContexts()
                }
            }
        }
        
        func inspectStoreDirectory() {
            guard let storeURL = container.persistentStoreDescriptions.first?.url else {
                print("❌ No store URL found")
                return
            }
            
            let storeDirectory = storeURL.deletingLastPathComponent()
            let fileManager = FileManager.default
            
            do {
                print("📁 Store directory: \(storeDirectory.path)")
                let files = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
                
                print("📋 Files in directory:")
                for file in files {
                    let fileSize = try fileManager.attributesOfItem(atPath: file.path)[.size] as? Int ?? 0
                    print("   - \(file.lastPathComponent) (\(fileSize) bytes)")
                }
                
                // Check if SQLite file exists and is valid
                if fileManager.fileExists(atPath: storeURL.path) {
                    print("✅ SQLite file exists")
                    // Try to read some basic info from the SQLite file
                    try checkSQLiteFile(at: storeURL)
                } else {
                    print("❌ SQLite file does not exist - this is a fresh install")
                }
                
            } catch {
                print("❌ Could not inspect store directory: \(error)")
            }
        }
        
        private func checkSQLiteFile(at url: URL) throws {
            // Basic SQLite file check
            let data = try Data(contentsOf: url)
            print("📊 SQLite file size: \(data.count) bytes")
            
            // Check if it's a valid SQLite file (first bytes should be "SQLite format 3")
            if data.count >= 15 {
                let header = String(data: data.subdata(in: 0..<15), encoding: .ascii) ?? "Invalid"
                print("📊 SQLite header: \(header)")
            }
        }
        
        private func completelyResetCoreData() {
            print("🔄 COMPLETELY RESETTING CORE DATA...")
            
            guard let storeURL = container.persistentStoreDescriptions.first?.url else {
                print("❌ No store URL available")
                return
            }
            
            do {
                // 1. Remove all persistent stores from coordinator
                for store in container.persistentStoreCoordinator.persistentStores {
                    try container.persistentStoreCoordinator.remove(store)
                }
                
                // 2. Delete ALL Core Data related files
                try deleteAllCoreDataFiles(at: storeURL)
                
                // 3. Reload with a fresh store
                print("🔄 Creating fresh Core Data store...")
                container.loadPersistentStores { [weak self] (storeDescription, error) in
                    if let error = error {
                        print("❌ Failed to create fresh store: \(error)")
                        // Last resort: try in-memory store
                        self?.fallbackToInMemoryStore()
                    } else {
                        print("✅ Fresh Core Data store created successfully!")
                        self?.configureContexts()
                        
                        // Verify it's working
                        self?.verifyCoreDataIsWorking()
                    }
                }
                
            } catch {
                print("❌ Reset failed: \(error)")
                fallbackToInMemoryStore()
            }
        }
        
        private func deleteAllCoreDataFiles(at storeURL: URL) throws {
            let fileManager = FileManager.default
            let storeDirectory = storeURL.deletingLastPathComponent()
            let baseName = storeURL.deletingPathExtension().lastPathComponent
            
            print("🗑️ Deleting all files with base name: \(baseName)")
            
            let files = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            var deletedCount = 0
            
            for file in files {
                let fileName = file.lastPathComponent
                // Delete all files that start with the base name (main db, wal, shm, etc.)
                if fileName.hasPrefix(baseName) {
                    try fileManager.removeItem(at: file)
                    print("   ✅ Deleted: \(fileName)")
                    deletedCount += 1
                }
            }
            
            print("🗑️ Total files deleted: \(deletedCount)")
            
            if deletedCount == 0 {
                print("ℹ️ No Core Data files found to delete - this might be a fresh install")
            }
        }
        
        private func configureContexts() {
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.shouldDeleteInaccessibleFaults = true
            
            print("✅ Core Data contexts configured")
        }
        
        private func verifyCoreDataIsWorking() {
            let context = container.viewContext
            
            // Try a simple fetch to verify Core Data is working
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Episode")
            request.fetchLimit = 1
            
            do {
                let count = try context.count(for: request)
                print("✅ Core Data verification: Successfully fetched data (\(count) total episodes)")
            } catch {
                print("❌ Core Data verification failed: \(error)")
            }
        }
        
        private func fallbackToInMemoryStore() {
            print("🔄 Falling back to in-memory store...")
            
            let inMemoryDescription = NSPersistentStoreDescription()
            inMemoryDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [inMemoryDescription]
            
            container.loadPersistentStores { [weak self] (_, error) in
                if let error = error {
                    print("❌ Even in-memory store failed: \(error)")
                } else {
                    print("✅ Using in-memory store as fallback")
                    self?.configureContexts()
                }
            }
        }
    }
