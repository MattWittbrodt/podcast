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
    let subscribeToPodcastUseCase: SubscribeToPodcastUseCase
    let manageDownloadsUseCase: ManageDownloadsUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        podcastRepository: PodcastRepository,
        subscribeToPodcastUseCase: SubscribeToPodcastUseCase,
        manageDownloadsUseCase: ManageDownloadsUseCase
    ) {
        self.subscribeToPodcastUseCase = subscribeToPodcastUseCase
        self.manageDownloadsUseCase = manageDownloadsUseCase
        Task {
            guard let podcasts = try? await podcastRepository.fetchAll() else { return }
            self.podcasts = podcasts
        }
    }
    
    func unsuscribeFromPodcast(_ podcast: PodcastRecord) async {
        try? await subscribeToPodcastUseCase.unsubscribe(podcast.objectId)
    }
}
