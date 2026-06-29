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
@Observable
class RecentEpisodesViewModel {
    var inFocusEpisode: EpisodeRecord?
    //var activeAlert: AlertType?
    
    private let dataManager: DataManager
    private let downloadManager: DownloadManager
    private let playbackManager: PlaybackManager
    private let refreshLibraryUseCase: RefreshLibraryUseCase
    private let manualDownloadUseCase: ProcessManualDownloadUseCase
    private let setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase
    private let playerVm: PlayerViewModel
    private let loadEpisodesUseCase: LoadEpisodeUseCase
    
    private var cancellables = Set<AnyCancellable>()
    var unlistenedEpisodes: [EpisodeRecord] = []
    //@Binding var showFullPlayer: Bool
    
    //private let onTogglePlayer: (Bool) -> Void

    init(
        dataManager: DataManager,
        downloadManager: DownloadManager,
        refreshLibraryUseCase: RefreshLibraryUseCase,
        processManualDownloadUseCase: ProcessManualDownloadUseCase,
        setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase,
        //showFullPlayer: Binding<Bool>,
        playbackManager: PlaybackManager,
        playerViewModel: PlayerViewModel,
        loadEpisodesUseCase: LoadEpisodeUseCase,
//        onTogglePlayer: @escaping (Bool) -> Void
    ) {
        self.dataManager = dataManager
        self.downloadManager = downloadManager
        self.refreshLibraryUseCase = refreshLibraryUseCase
        self.manualDownloadUseCase = processManualDownloadUseCase
        self.setEpisodeAsListenedUseCase = setEpisodeAsListenedUseCase
        self.playbackManager = playbackManager
        //self.onTogglePlayer = onTogglePlayer
        self.playerVm = playerViewModel
        self.loadEpisodesUseCase = loadEpisodesUseCase
        
        //self._showFullPlayer = showFullPlayer
        
        // TODO Set the fetchable in here directly?
        //self.unlistenedEpisodes = dataManager.unlistenedEpisodes
        self.observeChanges()
    }
    
    // Initial load
    func loadEpisodes() async {
        do {
            unlistenedEpisodes = try await loadEpisodesUseCase.forUnlistened()
        } catch {
            print("Bad episode loading")
        }
    }
    
    // Watches and re-loads episodes
    func observeChanges() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.loadEpisodes() }
        }
    }

    func refresh() async {
        await refreshLibraryUseCase.execute(notifyUser: false)
    }
    
    func startManualDownload(_ episode: EpisodeRecord, manualOverride: Bool) {
        manualDownloadUseCase.execute(for: episode, manualOverride: manualOverride)
    }
    
    func manualDownloadSwipeAction(_ episode: EpisodeRecord) {
        inFocusEpisode = episode
        
        if downloadManager.stopCellularDownload() {
            inFocusEpisode = episode
            //activeAlert = .cellularDownload
        } else {
            startManualDownload(episode, manualOverride: false)
        }
    }
    
    func episodeListenedSwipeAction(_ episode: EpisodeRecord) async {
        let _ = await setEpisodeAsListenedUseCase.execute(episode.objectId)
    }
    
    func selectEpisode(_ episode: EpisodeRecord) async {
        //onTogglePlayer(true)
        await playerVm.selectEpisode(episode.objectId)
//        playbackManager.loadEpisodeAndPlaylist(
//            episode: episode,
//            playlist: unlistenedEpisodes
////        )
//        Task {
//            try await playbackUseCase.play(episodeId: episode.objectID)
//        }
    }

}
