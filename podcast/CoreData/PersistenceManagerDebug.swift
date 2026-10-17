//
//  PersistenceManagerDebug.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import CoreData

#if DEBUG
extension PersistenceController {
    static var preview: PersistenceController = {
        let pc = PersistenceController(inMemory: true)
        let context = pc.container.viewContext
        
        // Seed a podcast
        let podcast = Podcast(context: context)
        podcast.title = "The Daily"
        podcast.author = "The New York Times"
        podcast.feedUrl = "https://feeds.simplecast.com/54nAGcIl"
        
        // Seed episodes
        var firstEpisode: Episode?
        for i in 0..<10 {
            
            let episode = Episode(context: context)
            //episode.id = UUID()
            episode.title = "Episode \(i)"
            episode.publishedDate = Date().addingTimeInterval(Double(-i) * 86400)
            episode.duration = 3600
            episode.listened = false
            episode.podcast = podcast
            //episode.audioUrl = "https://example.com/episode\(i).mp3"
            if i == 0 { firstEpisode = episode }
        }
        
        // Seed bookmarks on first episode
        if let episode = firstEpisode {
            let bookmark = Bookmark(context: context)
            bookmark.savedDate = Date()
            bookmark.startTime = 127
            bookmark.bookmarkEpisode = episode
            
            let bookmark2 = Bookmark(context: context)
            bookmark2.savedDate = Date().addingTimeInterval(-3600)
            bookmark2.startTime = 450
            bookmark2.bookmarkEpisode = episode
        }
        
        PersistenceController.createSamplePodcastAndEpisodes(
            context: context,
            title: "No Agenda Show",
            imageUrl: "https://noagendaassets.com/enc/1760304785.269_na-1807-art-feed.jpg",
            description: "Deconstructing Media with No Agenda, by Adam Curry and John C. Dvorak. Deconstructing Media with No Agenda, by Adam Curry and John C. Dvorak<p><strong>No Agenda Epsiode 1807 Live Sunday October 12th 2025"
        )
        do {
            try context.save()
            print("Preview data saved ✅")
            
            // Verify bookmarks were saved
            let request = Bookmark.fetchRequest()
            let count = try context.count(for: request)
            print("Bookmark count in preview: \(count)")
        } catch {
            print("Preview save failed: \(error)")  // ← catch the error
        }
        
        try? context.save()
        return pc
    }()
    
    static func createSamplePodcastAndEpisodes(
        context: NSManagedObjectContext,
        title: String,
        imageUrl: String,
        description: String
    ) {
        
        let podcast = Podcast(context: context)
        
        podcast.title = title
        podcast.feedUrl = "https://example.com/rss"
        podcast.imageUrl = imageUrl
        podcast.podcastDescription = description

        for i in 0...10 {
            let episode = Episode(context: context)
            episode.title = "Episode \(i)"
            episode.publishedDate = Date()
            episode.duration = Int16.random(in: 500...5000)
            episode.podcast = podcast
            try? context.save()
        }
    }
}
#endif
