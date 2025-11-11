//
//  ChapterVersion+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/31/25.
//

import Foundation
import CoreData

extension ChapterVersion {
    convenience init(version: String?,
                     context: NSManagedObjectContext) {
        self.init(context: context)
        self.version = version
    }
}
