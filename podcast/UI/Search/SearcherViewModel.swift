//
//  SearcherViewModel.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/20/26.
//

import Foundation
import Combine

struct PodcastDetailDestination: Identifiable {
    let podcast: IdentifiablePodcast
    let channel: RSSChannel
    
    var id: UUID { podcast.id }
}

@MainActor
class SearcherViewModel: ObservableObject {
    @Published var enteredText: String = "" {
        didSet {
            Task {
                searchResults = await search(term: enteredText)
            }
        }
    }
    @Published var searchResults: [PodcastIndexInfo] = []
    @Published var selectedPodcast: PodcastDetailDestination? = nil
    
    private let discoveryManager: DiscoveryManager
    
    init(appDependencies: AppDependencies) {
        self.discoveryManager = appDependencies.discoveryManager
    }
    
    func search(term: String) async -> [PodcastIndexInfo] {
        return await discoveryManager.search(term: term)
    }
    
    func setSelectedPodcast(_ detail: PodcastDetailDestination) {
        self.selectedPodcast = detail
    }
    
    func parseRSSfeedIntoPodcast(_ url: String) async {
        guard let rssChannel = await discoveryManager.parseKnownPodcast(feedUrl: url) else {
            return
        }
        self.selectedPodcast = PodcastDetailDestination(podcast: IdentifiablePodcast(rssChannel), channel: rssChannel)
        
    }
    
}
