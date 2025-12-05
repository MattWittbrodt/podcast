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
    var imgData: Data?
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
    
    // Checks fields in podcast and updates appropriately.
    func updateProperty<Value: Equatable>(
        // NO inout here
        _ currentPodcast: Podcast,
        _ keyPath: WritableKeyPath<Podcast, Value>,
        newValue: Value
    ) -> (podcast: Podcast, changed: Bool) {
        
        var mutablePodcast = currentPodcast
        
        if mutablePodcast[keyPath: keyPath] != newValue {
            mutablePodcast[keyPath: keyPath] = newValue
            return (podcast: mutablePodcast, changed: true)
        }
        return (podcast: currentPodcast, changed: false)
    }
    
    func updatePodcast(_ podcast: Podcast, channel: RSSChannel) async {
        var updatePodcast: Podcast = podcast
        var hasChanged: Bool = false
        
        func applyUpdate<Value: Equatable>(_ keyPath: WritableKeyPath<Podcast, Value>, newValue: Value) {
            let result = updateProperty(updatePodcast, keyPath, newValue: newValue)
            updatePodcast = result.podcast
            hasChanged = result.changed || hasChanged
        }
        
        applyUpdate(\.title, newValue: channel.title)
        applyUpdate(\.author, newValue: channel.author)
        applyUpdate(\.podcastDescription, newValue: channel.description)
        applyUpdate(\.imageUrl, newValue: channel.imageUrl)
        
        // Update image data (non-key path logic remains)
        if let newData = await updatePodcastImg(podcast) {
            podcast.imageData = newData
            hasChanged = true
        }
                
        // Save context if any change occurred
        if hasChanged {
            Task { @MainActor in
                dataManager.saveMainContext()
            }
        }
    }
    
    func updatePodcastImg(_ podcast: Podcast) async -> Data? {
        guard let imgUrl = podcast.imageUrl,
            let imgData = try? await loadImageFromWeb(url: imgUrl) else {
            return nil
        }
        
        if imgData != podcast.imageData {
            return imgData
        }
        return nil
    }
    
    private func fetchNewEpisodes(for podcast: Podcast) async -> [Episode] {
        guard let url = URL(string: podcast.feedUrl?.upgradeToHTTPS ?? "") else {return []}
                
        do {
            let parser = RSSFeedParser()
            let channel = try await parser.parse(from: url)
            
            // Updates podcast fields
            await updatePodcast(podcast, channel: channel)
            
            let existingGuids = Set(podcast.episodesArray.map { $0.guid })
            let newEpisodes = channel.items.filter { !existingGuids.contains($0.guid) }
            
            // Task group to apply the imgdata to each RSS episode
            let rssEpisodesImgData = await withTaskGroup(of: RSSEpisode.self, returning: [RSSEpisode].self) { group in
                for episode in newEpisodes {
                    group.addTask {
                        var updateEpisode = episode
                        guard let imgData = try? await loadImageFromWeb(url: episode.imageUrl) else {
                            print("\(updateEpisode.episodeTitle) - No image data.")
                            return episode
                        }
                        updateEpisode.imageData = imgData
                        return updateEpisode
                    }
                }
                
                var processedEpisodes = [RSSEpisode]()
                for await result in group {
                    let r = result
                    processedEpisodes.append(r)
                }
                return processedEpisodes
            }
            
            // Creating new objects
            let processedEpisodes = await Task { @MainActor in // Hop to the main actor context
                let processedEpisodes = rssEpisodesImgData.map {
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
