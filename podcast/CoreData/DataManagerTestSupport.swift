//
//  DataManagerTestSupport.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/15/25.
//

import Foundation

#if DEBUG
extension DataManager {
    static var preview: DataManager {
        let pm = PersistenceManager(inMemory: true)
        let dm = DataManager(persistence: pm)
        
        Task { @MainActor in
            dm.subscribeToPodcast(feedUrl: PodcastIndexInfo.example.url,
                                  channel: RSSChannel.example)
        }
        return dm
    }
}
#endif
