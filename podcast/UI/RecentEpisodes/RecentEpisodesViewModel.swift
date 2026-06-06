//
//  RecentEpisodesViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/12/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class RecentEpisodesViewModel: ObservableObject {
    @Published var inFocusEpisode: Episode?
    @Published var activeAlert: AlertType?
    @Published var unlistenedEpisodes: [Episode] = []
    
    private let dataManager: DataManager
    private let downloadManager: DownloadManager
    private let playbackManager: PlaybackManager
    private let refreshLibraryUseCase: RefreshLibraryUseCase
    private let manualDownloadUseCase: ProcessManualDownloadUseCase
    private let setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase
    private let startPlayingEpisodeUseCase: StartPlayingEpisodeUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    @Binding var showFullPlayer: Bool

    init(
        dataManager: DataManager,
        downloadManager: DownloadManager,
        refreshLibraryUseCase: RefreshLibraryUseCase,
        processManualDownloadUseCase: ProcessManualDownloadUseCase,
        setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase,
        startPlayingEpisodeUseCase: StartPlayingEpisodeUseCase,
        showFullPlayer: Binding<Bool>,
        playbackManager: PlaybackManager
    ) {
        self.dataManager = dataManager
        self.downloadManager = downloadManager
        self.refreshLibraryUseCase = refreshLibraryUseCase
        self.manualDownloadUseCase = processManualDownloadUseCase
        self.setEpisodeAsListenedUseCase = setEpisodeAsListenedUseCase
        self.startPlayingEpisodeUseCase = startPlayingEpisodeUseCase
        self.playbackManager = playbackManager
        self._showFullPlayer = showFullPlayer
        
        // TODO Set the fetchable in here directly?
        dataManager.$unlistenedEpisodes
            .receive(on: RunLoop.main)
            .sink { [weak self] newEpisodes in
                self?.unlistenedEpisodes = newEpisodes
            }
            .store(in: &cancellables)
    }

    func refresh() async {
        await refreshLibraryUseCase.execute(notifyUser: false)
    }
    
    func startManualDownload(_ episode: Episode, manualOverride: Bool) {
        manualDownloadUseCase.execute(for: episode, manualOverride: manualOverride)
    }
    
    func manualDownloadSwipeAction(_ episode: Episode) {
        inFocusEpisode = episode
        
        if downloadManager.stopCellularDownload() {
            inFocusEpisode = episode
            activeAlert = .cellularDownload
        } else {
            startManualDownload(episode, manualOverride: false)
        }
    }
    
    func episodeListenedSwipeAction(_ episode: Episode) async {
        await setEpisodeAsListenedUseCase.execute(episode)
    }
    
    func selectEpisode(_ episode: Episode) {
        showFullPlayer = true
//        playbackManager.loadEpisodeAndPlaylist(
//            episode: episode,
//            playlist: unlistenedEpisodes
//        )
        Task {
            try await startPlayingEpisodeUseCase.execute(episodeId: episode.objectID)
        }
    }

}
