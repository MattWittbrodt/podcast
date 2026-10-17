//
//  Bookmark.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/13/26.
//

import Foundation

extension Bookmark {
    static func createSavedFileName(title: String?, startTime: Double) -> String {
        "bookmark-\(title ?? "notitle")-\(startTime)"
    }
    
    func savedFileName() -> String {
        Bookmark.createSavedFileName(title: self.bookmarkEpisode?.title, startTime: self.startTime)
    }
}
