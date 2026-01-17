//
//  SearchManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/12/25.
//

import Foundation
import CryptoKit

class DiscoveryManager: ObservableObject {
    @Published var searchResults: [PodcastIndexInfo] = []
    @Published var rssChannel: RSSChannel? = nil
    @Published var selectedPodcast: IdentifiablePodcast? = nil
    
    private let searchService: PodcastSearchService
    private let dataManager: DataManager
    
    init(searchService: PodcastSearchService = PodcastIndexAPI(), dataManager: DataManager) {
        self.searchService = searchService
        self.dataManager = dataManager
    }
}

// MARK: Public API
extension DiscoveryManager {
    
    @MainActor
    func search(term: String) async {
        guard !term.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await searchService.searchByTerm(term: term)
        } catch {
            searchResults = []
        }
    }
    
    @MainActor
    func parseKnownPodcast(feedUrl: String) async {
        print("ParseKnown: \(feedUrl)")
        await self.parseRssFeed(feedUrl: feedUrl)
        
        guard let rssChannel = rssChannel else {
            print("Bad parsing")
            return
        }
        
        // Then show the sheet
        await MainActor.run {
            selectedPodcast = IdentifiablePodcast(rssChannel)
        }
    }
    
    func subscribeToPodcast() {
        guard let url = selectedPodcast?.podcast.rssUrl(),
              let channel = rssChannel
        else {
            print("No url or channel found")
            return
        }
        Task { @MainActor in
            dataManager.subscribeToPodcast(feedUrl: url, channel: channel )
        }
    }
}

// private API
private extension DiscoveryManager {
    func parseRssFeed(feedUrl: String) async {
        
        guard let url = URL(string: feedUrl.upgradeToHTTPS ?? "") else {
            return
        }
        let parser = RSSFeedParser()
        do {
            var channelFromRSS = try await parser.parse(from: url)
            
            // Add image data
            let imgData = try? await loadImageFromWeb(url: channelFromRSS.imageUrl)
            channelFromRSS.podcastImageData = imgData
            
            await MainActor.run {
                self.rssChannel = channelFromRSS
            }
        } catch {
            print("Error decoding rss")
        }
    }
}
