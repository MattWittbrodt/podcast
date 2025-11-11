//
//  Bookmark+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 8/1/25.
//

import Foundation
import CoreData

extension Bookmark {
    
    @discardableResult
    convenience init(startTime: Int64,
                     dateTime: Date,
                     context: NSManagedObjectContext) {
        self.init(context: context)
        
        context.performAndWait {
            self.startTime = startTime
            self.dateTime = dateTime
        }
    }
    
    static func allBookmarks() -> NSFetchRequest<Bookmark> {
        let request = Bookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Bookmark.dateTime, ascending: false)]
        return request
    }
}
