//
//  DiscoveryManagerTestSupport.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/15/25.
//

import Foundation

#if DEBUG
extension DiscoveryManager {
    @MainActor
    static var preview: DiscoveryManager {
        let pm = PersistenceManager(inMemory: true)
        let dm = DataManager(persistence: pm)
        let manager = DiscoveryManager(dataManager: dm)
        
        // Mock selected podcast
        manager.rssChannel = RSSChannel.example
        manager.selectedPodcast = PodcastIndexInfo.example
        
        return manager
    }
}
#endif
