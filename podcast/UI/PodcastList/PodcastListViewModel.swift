//
//  PodcastListViewModel.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/17/26.
//

import Foundation
import Combine

@MainActor
@Observable
class PodcastListViewModel {
    var podcasts: [PodcastRecord] = []
    
    var inFocusEpisode: Episode?
    //var activeAlert: AlertType?
    
    //private let dataManager: DataManager
    //private let downloadManager: DownloadManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(podcastRepository: PodcastRepository) {
        //self.dataManager = dataManager
        //self.downloadManager = downloadManager
        Task {
            guard let podcasts = try? await podcastRepository.fetchAll() else { return }
            self.podcasts = podcasts
        }
    }
    
    func unsuscribeFromPodcast(_ podcast: PodcastRecord) {
        //Podcast.delete(podcast: podcast)
        //self.dataManager.saveMainContext()
        //self.dataManager.refreshEpisodes()
        //self.dataManager.refreshPodcasts()
    }

}
