//
//  PodcastListViewModel.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/17/26.
//

import Foundation
import Combine

@MainActor
class PodcastListViewModel: ObservableObject {
    @Published var podcasts: [Podcast] = []
    
    @Published var inFocusEpisode: Episode?
    @Published var activeAlert: AlertType?
    
    private let dataManager: DataManager
    private let downloadManager: DownloadManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(appDependencies: AppDependencies) {
        self.dataManager = appDependencies.dataManager
        self.downloadManager = appDependencies.downloadManager
        
        // TODO Set the fetchable in here directly?
        dataManager.$podcasts
            .receive(on: RunLoop.main)
            .sink { [weak self] podcasts in
                self?.podcasts = podcasts
            }
            .store(in: &cancellables)
    }
    
    func unsuscribeFromPodcast(_ podcast: Podcast) {
        Podcast.delete(podcast: podcast)
        //self.dataManager.saveMainContext()
        //self.dataManager.refreshEpisodes()
        //self.dataManager.refreshPodcasts()
    }

}
