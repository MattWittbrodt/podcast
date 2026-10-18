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
        lhs.objectId == rhs.objectId &&
        lhs.lastListened == rhs.lastListened //&&
        //lhs.duration == rhs.duration &&
        //lhs.playbackRate == rhs.playbackRate
    }
}

extension EpisodeRecord {
    func chapter(at time: TimeInterval) -> ChapterRecord? {
        // Since `chapters` is pre-sorted chronologically, finding the current 
        // chapter via `last` is extremely lightweight and fast.
        chapters.last { time >= Double($0.startTime) }
    }
    
    func savedFileName() -> String {
        Episode.makeFileName(title: self.episodeTitle, guid: self.guid)
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

extension EpisodeRecord {
    static var preview: EpisodeRecord {
        
        let context = PersistenceController.preview.container.viewContext
        let episode = Episode(context: context)
        episode.title = "Preview Episode"
        episode.duration = 3600
        episode.lastListened = 120
        try? context.save()
        
        return EpisodeRecord(
            objectId: episode.objectID,
            episodeTitle: "Preview Episode",
            podcastTitle: "Preview Podcast",
            playbackRate: 1.0,
            duration: 3600,
            lastListened: 120,
            episodeDescription: "Episode Description",
            audioUrl: URL(string: "Sampleaudio")!,
            chapters: [],
            guid: "sampleGuid",
            imgData: nil,
            publishedDate: Date(),
            enclosureUrl: "EnclosureUrl",
            manualDownload: false,
        )
    }
    
    static func makeSampleForTest(
        title: String,
        publishedDate: Date,
        audioUrl: URL?,
        context: NSManagedObjectContext?,
    ) -> EpisodeRecord {
        let context = context ?? PersistenceController.preview.container.viewContext
        
        let episode = Episode(context: context)
        episode.title = "Preview Episode"
        episode.duration = 3600
        episode.lastListened = 120
        try? context.save()
        
        return EpisodeRecord(
            objectId: episode.objectID,
            episodeTitle: title,
            podcastTitle: "Preview Podcast",
            playbackRate: 1.0,
            duration: 3600,
            lastListened: 120,
            episodeDescription: "Episode Description",
            audioUrl: audioUrl ?? URL(string: "Sampleaudio")!,
            chapters: [],
            guid: "sampleGuid",
            imgData: nil,
            publishedDate: publishedDate,
            enclosureUrl: "EnclosureUrl",
            manualDownload: false,
        )
    }
}

struct ChapterRecord {
    let imageData: Data?
    let imageUrl: String?
    let startTime: Int16
    let chapterTitle: String
}

struct BookmarkRecord: Identifiable, Equatable {
    var id: NSManagedObjectID { objectId }
    let objectId: NSManagedObjectID
    let savedDate: Date
    let customLabel: String?
    let audioFilePath: URL
    let isAudioFromEpisode: Bool
    let startTime: Double
    let episodeId: NSManagedObjectID
    let episodeTitle: String
    let podcastTitle: String
    let publishedDate: Date?
    
    static func == (lhs: BookmarkRecord, rhs: BookmarkRecord) -> Bool {
        lhs.objectId == rhs.objectId
    }
}

extension BookmarkRecord {
    func savedFileName() -> String {
        Bookmark.createSavedFileName(title: self.episodeTitle, startTime: self.startTime)
    }
    
    static func makeSampleForTest(
        bookmark: Bookmark,
        episode: Episode
    ) -> BookmarkRecord {
        BookmarkRecord(
            objectId: bookmark.objectID,
            savedDate: Date.distantPast,
            customLabel: bookmark.customLabel,
            audioFilePath: URL(fileURLWithPath: "/dev/null"),
            isAudioFromEpisode: true,
            startTime: 10,
            episodeId: episode.objectID,
            episodeTitle: episode.title ?? "Episode Debug",
            podcastTitle: "Tet Podcast Tile",
            publishedDate: Date.distantPast
        )
    }
}
