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
    @Published var selectedPodcast: PodcastIndexInfo? = nil
    
    private let searchService: PodcastSearchService
    private let dataManager: DataManager
    
    init(searchService: PodcastSearchService = PodcastIndexAPI(), dataManager: DataManager) {
        self.searchService = searchService
        self.dataManager = dataManager
    }
    
    @MainActor
    func search(term: String) async {
        print("Searching for \(term)")
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
    
    func subscribeToPodcast() {
        guard let url = selectedPodcast?.url,
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
