//
//  PodcastFeedService.swift
//  Planecastv2
//
//  Created by Matt Wittbrodt on 11/8/25.
//

import Foundation

struct ChapterResponse: Decodable {
    let version: String
    let chapters: [ChapterInfo]
}

struct ChapterInfo: Hashable, Codable {
    let startTime: Int16
    let title: String?
    let img: String?
}

class PodcastFeedService: ObservableObject {
    private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    func updateAllSubscribedPodcasts() async -> [Episode] {
        print("FeedService: starting full sync on launch")
        do {
            let feeds = try await dataManager.loadSuscribedPodcasts()
            // Returning episodes first, then downloading all later
            let newEpisodes = await withTaskGroup(of: [Episode].self, returning: [Episode].self) { group in
                for podcast in feeds {
                    group.addTask { await self.fetchNewEpisodes(for: podcast) }
                }
                
                var episodes = [Episode]()
                for await result in group {
                    episodes.append(contentsOf: result)
                }
                return episodes
            }
            print("FeedService: Full update complete. Added \(newEpisodes.count) new episodes")
            return newEpisodes
        } catch {
            print("Failed to load podcasts")
            return []
        }
    }
}

// Function to fetch new items
extension PodcastFeedService {
    private func fetchNewEpisodes(for podcast: Podcast) async -> [Episode] {
        guard let url = URL(string: podcast.feedUrl?.upgradeToHTTPS ?? "") else {return []}
                
        do {
            let parser = RSSFeedParser()
            let channel = try await parser.parse(from: url)
            let existingGuids = Set(podcast.episodesArray.map { $0.guid })
            let newEpisodes = channel.items.filter { !existingGuids.contains($0.guid) }
            
            // Creating new objects
            let processedEpisodes = await Task { @MainActor in // Hop to the main actor context
                let processedEpisodes = newEpisodes.map {
                    dataManager.saveEpisodeToPodcast($0, for: podcast)
                }
                return processedEpisodes
            }.value
            
            return processedEpisodes
        } catch {
            print("❌ Failed to fetch episodes for \(podcast.title): \(error)")
            return []
        }
    }
    
    // Function to fetch new chapters
    static func fetchNewChapters(for chaptersUrl: String) async throws -> ChapterResponse? {
        guard let url = URL(string: chaptersUrl) else {
            throw ChapterError.badUrl(chaptersUrl)
        }
            
        let decoder = JSONDecoder()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            throw ChapterError.noData(chaptersUrl)
        }
            
        do {
            let decodedChapters = try decoder.decode(ChapterResponse.self, from: data)
            return decodedChapters
        } catch {
            throw ChapterError.decoderError(chaptersUrl,"\(error)")
        }
    }
}
