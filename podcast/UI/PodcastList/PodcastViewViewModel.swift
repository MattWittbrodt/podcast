//
//  PodcastViewViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/17/26.
//

import Foundation
import SwiftUI

@MainActor
class PodcastViewModel: ObservableObject {
    
    @Published var episodes: [Episode] = []

    private let dataManager: DataManager
    private let downloadManager: DownloadManager
    private let startPlayingEpisodeUseCase: StartPlayingEpisodeUseCase
    private let episodeRepository: EpisodeRepository
    private let podcast: Podcast
    @Binding var showFullPlayer: Bool
    
    //private var cancellables = Set<AnyCancellable>()
    
    init(
        appDependencies: AppDependencies,
        startPlayingEpisodeUseCase: StartPlayingEpisodeUseCase,
        podcast: Podcast,
        episodeRepository: EpisodeRepository,
        showFullPlayer: Binding<Bool>
    ) {
        self.dataManager = appDependencies.dataManager
        self.downloadManager = appDependencies.downloadManager
        self.startPlayingEpisodeUseCase = startPlayingEpisodeUseCase
        self.podcast = podcast
        self.episodeRepository = episodeRepository
        self._showFullPlayer = showFullPlayer
    }
    
    func markAllListened() {
        episodeRepository.markAllEpisodesAsListened(for: podcast)
    }
    
    // TODO: improve error handling
    func getAllEpisodes() async {
        self.episodes = (try? await episodeRepository.getAllEpisodesForPodcast(podcast)) ?? []
    }
    
    func startDownloadForEpisode(_ episode: Episode) {
        downloadManager.startDownload(for: episode)
    }
    
    func markEpisodeAsUnlistened(_ episode: Episode) {
        episodeRepository.markEpisodeAsUnlistened(episode)
    }
    
    func handleEpisodeSelection(_ episode: Episode) {
        showFullPlayer = true
        Task {
            try await startPlayingEpisodeUseCase.execute(episodeId: episode.objectID)
        }
    }
}
