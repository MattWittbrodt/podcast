//
//  API.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/26/25.
//

import Foundation
import CoreData
import UIKit
//
//struct FeedResponse: Codable {
//    let feed: PodcastInfo
//}

struct EpisodeByFeedResponse: Codable {
    let items: [EpisodeInfo]
}

struct EpisodeInfo: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var feedId: Int64
    var guid: String
    var image: String
    var enclosureUrl: String
    var description: String
    var duration: Int16
    var datePublished: Int64
    var chaptersUrl: String?
    
    // Format date
    func formattedDate(epochTime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
}



