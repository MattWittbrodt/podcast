//
//  RSSParserDataModels.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/22/25.
//

import Foundation

struct PodcastChapters: Codable {
    let url: URL
}

struct Enclosure: Codable {
    let url: URL
    let type: String
    let length: Int
}

// MARK: - Data Models
struct RSSChannel: Codable {
    let title: String
    let link: String
    let author: String
    let description: String
    let imageUrl: String
    var items: [RSSEpisode]
    var podcastImageData: Data?
}

struct RSSEpisode: Identifiable, Codable {
                        
    let id = UUID()
    let episodeTitle: String
    let link: String
    let displayDescription: String
    let guid: String
    let imageUrl: String
    let episodeDate: Date
    let episodeDuration: Int16
    let chapters: PodcastChapters?
    let enclosureUrl: String?
    let isDownloaded = false
    var imageData: Data? = nil
    var isListened = false
    let lastListenedTime: Int16 = 0
    let chaptersUrl: String?
    let podcastImgData: Data? = nil
    let podcastTitle: String = ""
    
    enum CodingKeys: String, CodingKey {
        case episodeTitle, link, displayDescription, episodeDate, guid, chapters, imageUrl, episodeDuration, enclosureUrl, chaptersUrl, podcastImgData
    }
    
//    mutating func addImageData() async {
//        self.imageData = try? await loadImageFromWeb(url: imageUrl)
//    }
    
}
