//
//  Settings+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 1/24/26.
//

import Foundation
import CoreData

extension UserSettings {
    static func create(context: NSManagedObjectContext) -> UserSettings {
        // Defaults have been specified
        let entity = UserSettings(context: context)
        entity.updateTime = Date()
        return entity
    }
}
