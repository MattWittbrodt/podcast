//
//  PodcastViewViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/17/26.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class PodcastViewModel {
    
    var episodes: [EpisodeRecord] = []

    private let dataManager: DataManager
    private let downloadManager: DownloadManager
    private let playbackUseCase: PlaybackUseCase
    private let podcastRepository: PodcastRepository
    private let podcast: PodcastRecord
    private let loadEpisodeUseCase: LoadEpisodeUseCase
    //var showFullPlayer: Bool
    
    //private var cancellables = Set<AnyCancellable>()
    
    init(
        dataManager: DataManager,
        downloadManager: DownloadManager,
        playbackUseCase: PlaybackUseCase,
        podcast: PodcastRecord,
        podcastRepository: PodcastRepository,
        loadEpisodeUseCase: LoadEpisodeUseCase,
        //showFullPlayer: Binding<Bool>
    ) {
        self.dataManager = dataManager
        self.downloadManager = downloadManager
        self.playbackUseCase = playbackUseCase
        self.podcast = podcast
        self.podcastRepository = podcastRepository
        self.loadEpisodeUseCase = loadEpisodeUseCase
        //self._showFullPlayer = showFullPlayer
    }
    
    func markAllListened() {
        Task {
            try? await podcastRepository.markAllEpisodesAsListened(for: podcast.objectId)
        }
    }
    
    // TODO: improve error handling
    func getAllEpisodes() async {
        self.episodes = (try? await loadEpisodeUseCase.forPodcast(podcast.objectId)) ?? []
    }
    
    func startDownloadForEpisode(_ episode: EpisodeRecord) {
        //TODO
        //downloadManager.startDownload(for: episode)
    }
    
    func markEpisodeAsUnlistened(_ episode: EpisodeRecord) {
        //TODO
        //episodeRepository.markEpisodeAsUnlistened(episode)
    }
    
//    func handleEpisodeSelection(_ episode: Episode) {
//        showFullPlayer = true
//        Task {
//            try await playbackUseCase.play(episode: episode.objectID)
//        }
//    }
}
