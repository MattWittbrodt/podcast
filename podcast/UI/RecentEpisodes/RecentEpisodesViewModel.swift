//
//  RecentEpisodesViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/12/26.
//

import Foundation
import Combine
import SwiftUI
import CoreData

@MainActor
@Observable
class RecentEpisodesViewModel {
    var inFocusEpisode: EpisodeRecord?
    
    private let refreshLibraryUseCase: RefreshLibraryUseCase
    private let manualDownloadUseCase: ProcessManualDownloadUseCase
    private let setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase
    private let playerVm: PlayerViewModel
    private let loadEpisodesUseCase: LoadEpisodeUseCase
    private let manageDownloadsUseCase: ManageDownloadsUseCase
    
    private var cancellables = Set<AnyCancellable>()
    var unlistenedEpisodes: [EpisodeRecord] = []
    
    private var reloadTask: Task<Void, Never>?

    init(
        refreshLibraryUseCase: RefreshLibraryUseCase,
        processManualDownloadUseCase: ProcessManualDownloadUseCase,
        setEpisodeAsListenedUseCase: SetEpisodeAsListenedUseCase,
        playerViewModel: PlayerViewModel,
        loadEpisodesUseCase: LoadEpisodeUseCase,
        manageDownloadsUseCase: ManageDownloadsUseCase
    ) {
        self.refreshLibraryUseCase = refreshLibraryUseCase
        self.manualDownloadUseCase = processManualDownloadUseCase
        self.setEpisodeAsListenedUseCase = setEpisodeAsListenedUseCase
        self.playerVm = playerViewModel
        self.loadEpisodesUseCase = loadEpisodesUseCase
        self.manageDownloadsUseCase = manageDownloadsUseCase
    }
    
    func loadEpisodes() async {
        do {
            let episodes = try await loadEpisodesUseCase.forUnlistened()
            unlistenedEpisodes = episodes
        } catch {
            print("Bad episode loading: \(error)")
        }
    }
    
    // Watches and re-loads episodes
    func observeChanges(coordinator: NSPersistentStoreCoordinator) {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: coordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadTask?.cancel()
                self?.reloadTask = Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                    await self?.loadEpisodes()
                }
            }
        }
    }

    func refresh() async {
        await refreshLibraryUseCase.execute(notifyUser: false)
    }
    
    func manualDownloadSwipeAction(_ episode: EpisodeRecord) {
        inFocusEpisode = episode
        do {
            try manualDownloadUseCase.execute(for: episode, manualOverride: false)
        } catch {
            print("Manual download failed")
        }
    }
    
    func episodeListenedSwipeAction(_ episode: EpisodeRecord) async {
        let _ = await setEpisodeAsListenedUseCase.execute(episode.objectId)
    }
    
    func selectEpisode(_ episode: EpisodeRecord) async {
        await playerVm.selectEpisode(episode.objectId)
    }
    
    func episodeDownloadState(_ episode: EpisodeRecord) -> DownloadState {
        manageDownloadsUseCase.episodeState(episode: episode)
    }
}
