//
//  DataManagerTestSupport.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/15/25.
//

import Foundation

//#if DEBUG
//extension DataManager {
//    static var preview: DataManager {
//        let pm = PersistenceManager(inMemory: true)
//        let dm = DataManager(persistence: pm, downloadManager: DownloadManager())
//        
//        Task { @MainActor in
//            dm.subscribeToPodcast(feedUrl: PodcastIndexInfo.example.url,
//                                  channel: RSSChannel.example)
//            
//            print(dm.podcasts.first!)
//        }
//        return dm
//    }
//}
//#endif
