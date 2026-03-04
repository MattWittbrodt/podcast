//
//  PodcastTestSupport.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/3/26.
//

import Foundation
import CoreData

#if DEBUG
extension Podcast {
    static func createSample(context: NSManagedObjectContext) -> Podcast {
        
        let podcast = Podcast(context: context)
        
        podcast.title = "Preview Podcast"
        podcast.feedUrl = "https://example.com/rss"
        podcast.imageUrl = "https://noagendaassets.com/enc/1760304785.269_na-1807-art-feed.jpg";
        podcast.podcastDescription = "Deconstructing Media with No Agenda, by Adam Curry and John C. DvorakDeconstructing Media with No Agenda, by Adam Curry and John C. Dvorak<p><strong>No Agenda Epsiode 1807 Live Sunday October 12th 202";
        
        for i in 0...10 {
            let episode = Episode(context: context)
            episode.title = "Episode \(i)"
            episode.publishedDate = Date()
            episode.duration = 500
            episode.podcast = podcast
            try? context.save()
        }
        
        return podcast
    }
}
#endif
