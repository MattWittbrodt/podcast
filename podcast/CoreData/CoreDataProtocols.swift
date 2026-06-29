//
//  Protocols.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/17/26.
//

import Foundation
import CoreData

struct PodcastRecord {
    let objectId: NSManagedObjectID
    let podcastTitle: String
    let author: String
    let imageData: Data?
    let imageUrl: String?
}

struct EpisodeRecord: Equatable {
    let objectId: NSManagedObjectID
    let episodeTitle: String
    let podcastTitle: String
    let playbackRate: Float
    let duration: Int16
    let lastListened: Double
    let episodeDescription: String?
    let audioUrl: URL
    let chapters: [ChapterRecord]
    let guid: String?
    let imgData: Data?
    let publishedDate: Date?
    let enclosureUrl: String?
    let manualDownload: Bool
    
    static func == (lhs: EpisodeRecord, rhs: EpisodeRecord) -> Bool {
        lhs.objectId == rhs.objectId
    }
}

extension EpisodeRecord {
    func chapter(at time: TimeInterval) -> ChapterRecord? {
        // Since `chapters` is pre-sorted chronologically, finding the current 
        // chapter via `last` is extremely lightweight and fast.
        chapters.last { time >= Double($0.startTime) }
    }
    
    func savedFileName() -> String {
        let episodeTitle = self.episodeTitle.replacingOccurrences(of: "/", with: "-")
        return "\(episodeTitle)-\(self.guid ?? "Default Guid")"
    }
    
    var formattedDate: String {
        guard let date = publishedDate else { return "" }
        let calendar = Calendar.current
        
        // 1. Handle the "Relative" cases first
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        // 2. Handle the "Calendar Year" check
        let isThisYear = calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        
        if isThisYear {
            // "Feb 4"
            return date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            // "Feb 4, 2025"
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

struct ChapterRecord {
    let imageData: Data?
    let imageUrl: String?
    let startTime: Int16
    let chapterTitle: String
}
