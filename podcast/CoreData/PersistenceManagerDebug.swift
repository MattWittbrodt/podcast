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
        //podcast.id = UUID()
        podcast.title = "The Daily"
        podcast.author = "The New York Times"
        podcast.feedUrl = "https://feeds.simplecast.com/54nAGcIl"
        
        // Seed episodes
        for i in 0..<10 {
            let episode = Episode(context: context)
            //episode.id = UUID()
            episode.title = "Episode \(i)"
            episode.publishedDate = Date().addingTimeInterval(Double(-i) * 86400)
            episode.duration = 3600
            episode.listened = false
            episode.podcast = podcast
            //episode.audioUrl = "https://example.com/episode\(i).mp3"
        }
        
        try? context.save()
        return pc
    }()
}
#endif
