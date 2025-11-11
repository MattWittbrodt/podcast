//
//  SearcherViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/22/25.
//

import Foundation
import CoreData
import UIKit

final class PodcastSearchViewModel: ObservableObject {
    @Published var searchResults: [PodcastInfo] = []
    private var podcastIndexManager = PodcastIndexModel()
       
    func searchPodcasts(searchTerm: String) async {
        let results = try? await podcastIndexManager.searchByTerm(searchTerm: searchTerm)
        Task {@MainActor in
            self.searchResults = results ?? []
        }
    }
}
