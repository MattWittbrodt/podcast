//
//  BookmarksViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 8/2/25.
//

import Foundation
import CoreData

@Observable class BookmarksViewModel {
    var bookmarks: [Bookmark] = []
    private var context: NSManagedObjectContext?
    
    func setup(context: NSManagedObjectContext?) {
        self.context = context
    }
    
    func loadBookmarks() async {
        guard let context = context else { return }
        
        do {
            let fetchedBookmarks = try await context.perform {
                try context.fetch(Bookmark.allBookmarks())
            }
            bookmarks = fetchedBookmarks
        } catch {
            print("Error fetching episodes: \(error.localizedDescription)")
        }
    }
}
