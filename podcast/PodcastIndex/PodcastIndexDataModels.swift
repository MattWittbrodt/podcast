//
//  PodcastIntroDataModels.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/18/25.
//

import Foundation
import CoreData

struct SearchResponses: Codable {
    let feeds: [PodcastInfo]
}

struct PodcastInfo: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let image: String
    let author: String
    let description: String
    let url: String
    
    func to_store(context: NSManagedObjectContext) -> Podcast? {
        let request = Podcast.queryByFeedId(Int32(self.id))
        request.fetchLimit = 1
        do {
            let result = try context.fetch(request)
            if result.isEmpty {
                let podcast = Podcast(
                    title: self.title,
                    author: self.author,
                    image: self.image,
                    podcastDescription: self.description,
                    feedUrl: self.url,
                    context: context)
                return podcast
            } else {
                return result.first!
            }
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
        return nil
    }
    
    static func from_rss(url: String) async throws -> PodcastInfo {
        var rssParser = RSSFeedParser()
        
        guard let url = URL(string: upgradeToHTTPS(urlString: url) ?? "") else {
            throw RSSParserError.invalidUrl(url)
        }
        
        do {
            // 1. Fetch channel data
            let channelData: RSSChannel? = try await rssParser.parse(from: url)
            guard var channelData = channelData else {
                throw RSSParserError.parseError("Bad channel parsing")
            }
            
            return PodcastInfo(
                id: 1,
                title: channelData.title,
                image: channelData.imageUrl,
                author: channelData.author,
                description: channelData.description,
                url: url.absoluteString
            )
        } catch {
            throw RSSParserError.parseError(error.localizedDescription)
        }
    }
    
    static var previewExample: PodcastInfo {
        return PodcastInfo(
            id: 1,
            title: "Example Podcast",
            image: "https://megaphone.imgix.net/podcasts/401fd1f4-788f-11ee-b782-0bfaeeb8c455/image/Square002_FPL_logo.jpg?ixlib=rails-4.3.1&max-w=3000&max-h=3000&fit=crop&auto=format,compress",
            author: "The podcast author",
            description: "This is an example podcast.",
            url: "https://feeds.megaphone.fm/COMG5751810297"
        )
    }
}
