//
//  Podcast+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 4/21/25.
//

import Foundation
import CoreData

extension Podcast {
    
    var title: String {
        get { title_ ?? ""  }
        set { title_ = newValue }
    }
    
    var author: String {
        get { author_ ?? ""  }
        set { author_ = newValue }
    }
    
    var podcastDescription: String {
        get { podcastDescription_ ?? ""  }
        set { podcastDescription_ = newValue }
    }
    
    convenience init(title: String,
                     author: String,
                     image: String,
                     podcastDescription: String,
                     imageData: Data? = nil,
                     feedUrl: String,
                     context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = title
        self.author = author
        self.imageUrl = image
        self.imageData = imageData
        self.feedUrl = feedUrl
        self.podcastDescription = podcastDescription
    }
    
    static func delete(podcast: Podcast) {
        guard let context = podcast.managedObjectContext else { return }
        context.delete(podcast)
    }
    
    static func setAllListened(podcast: Podcast) async {
        guard let context = podcast.managedObjectContext,
                  let episodes = podcast.episodes as? Set<Episode> else { return }
        
        for episode in episodes {
            await Episode.handleListened(episode: episode)
        }
        try? context.save()
    }
    
    static func allSaved(_ predicate: NSPredicate = .all) -> NSFetchRequest<Podcast> {
        let request = Podcast.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Podcast.title_, ascending: true)]
        request.predicate = predicate
                
        return request
    }
    
    static func queryByFeedId(_ feedId: Int32) -> NSFetchRequest<Podcast> {
        let request = Podcast.fetchRequest()
        request.predicate = NSPredicate(format: "feedId == %d", feedId)
        return request
    }
    
    //MARK: Preview Helpers
//    static var example: Podcast {
//        let context = PersistenceController.preview.container.viewContext
//        let testPodcast = Podcast(
//            title: "The 59th Minute FPL Podcast",
//            author: "FPL General",
//            image: "https://megaphone.imgix.net/podcasts/28b51a68-e5c0-11ed-8327-fbf3235c5405/image/60854458c4d1acdf4e1c2f79c4137142d85d78e379bdafbd69bd34c85f5819ad.jpg?ixlib=rails-4.3.1&max-w=3000&max-h=3000&fit=crop&auto=format,compress",
//            podcastDescription: "The FPL General helps Fantasy Football managers prepare for each Gameweek, offering his thoughts on captaincy, transfers and a look at his 'watchlist' of the best players.",
//            feedUrl: "https://feeds.megaphone.fm/COMG4750541235",
//            context: context
//        )
//        
//        return testPodcast
//    }
}


extension Podcast {
    /// Configures a Podcast managed object with RSS channel data
    /// - Parameter channelData: Parsed RSS feed data
    func configure(with channelData: RSSChannel, feedUrl: String) {
        // Required properties
        self.title = channelData.title
        self.feedUrl = feedUrl
        self.imageUrl = channelData.imageUrl
        
        // Optional properties with nil coalescing
        self.author = channelData.author
        
    }
}
