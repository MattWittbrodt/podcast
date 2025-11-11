//
//  PodcastIntroViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/22/25.
//

import Foundation
import CoreData

@MainActor
final class PodcastIntroViewModel: ObservableObject {
    @Published var episodes: [RSSEpisode] = []
    @Published var imageData: Data?
    @Published var alertError: RSSParserError?
    
    private var rssParser = RSSFeedParser()
    var channelData: RSSChannel?
    var podcastUrl: String
    var context: NSManagedObjectContext?
    
    init(podcastUrl: String) { self.podcastUrl = podcastUrl }
    
    func setContext(_ context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchPodcastData() async {
        guard let url = URL(string: upgradeToHTTPS(urlString: self.podcastUrl) ?? "") else {
            alertError = RSSParserError.invalidUrl(self.podcastUrl)
            return
        }
        
        do {
            // 1. Fetch channel data
            print(url)
            let channelData: RSSChannel? = try await rssParser.parse(from: url)
            guard var channelData = channelData else {
                return
            }
            let podcastImageData = try? await loadImageFromWeb(url: channelData.imageUrl)
            var episodes = channelData.items
            
            // Process images concurrently
            await withTaskGroup(of: (Int, Data?).self) { group in
                for (index, episode) in episodes.enumerated() {
                    group.addTask {
                        let data = try? await loadImageFromWeb(url: episode.imageUrl)
                        let finalImgData = data ?? podcastImageData
                        return (index, finalImgData)
                    }
                }
                
                // Apply results to episodes
                for await (index, imageData) in group {
                    episodes[index].imageData = imageData
                }
            }
            
            // Update the published episodes
            await MainActor.run {
                self.imageData = podcastImageData
                self.episodes = episodes
                channelData.items = episodes
                self.channelData = channelData
            }
            
        } catch {
            alertError = RSSParserError.parseError(self.podcastUrl)
        }
    }
    
    func subscribeToPodcast() {
        guard let context = self.context, let channelData = channelData else {
            return
        }
        
        context.perform {
            do {
                let dataPodcast = Podcast(context: context)
                dataPodcast.configure(with: channelData, feedUrl: self.podcastUrl)
                
                // Create and track episodes
                let episodes = channelData.items.map { item -> Episode in
                    let episode = Episode(context: context)
                    episode.configure(with: item)
                    episode.podcast = dataPodcast
                    episode.listened = true
                    return episode
                }

                // Find the most recent podcast and prep for listening: download and set listened to false
                if let mostRecent = episodes.max(by: {
                    ($1.publishedDate ?? Date.distantPast) > ($0.publishedDate ?? Date.distantPast)
                }) {
                    mostRecent.listened = false
                    Task {
                        let downloadData = try await downloadDataUtils.downloadEpisodetoFile(url: mostRecent.enclosureUrl ?? "", episodeId: mostRecent.uuid?.uuidString ?? "no id")
                        if let duration = downloadData.duration {
                            mostRecent.duration = duration
                        }
                    }
                }
                try context.save()
            } catch {
                print("Subscription failed: \(error)")
                context.rollback()
            }
        }
    }
    
}
