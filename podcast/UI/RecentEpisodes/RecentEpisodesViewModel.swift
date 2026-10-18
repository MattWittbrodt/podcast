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
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            log("NSManagedObjectContextDidSave received")
            Task { @MainActor [weak self] in
                self?.handleChangeNotification()
            }
        }
    }
    
    private func handleChangeNotification() {
        // Debounce incoming saves so rapid successive saves don't cause multiple reloads
        // or get dropped prematurely.
        reloadTask?.cancel()
        reloadTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }
            log("Reloading episodes from context save")
            await loadEpisodes()
        }
    }

    func refresh() async {
        await refreshLibraryUseCase.execute(notifyUser: false)
        await loadEpisodes()
        log("RecentEpisodesViewModel refresh finished")
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
        do {
            let _ = try await setEpisodeAsListenedUseCase.execute(episode)
            await loadEpisodes()
        } catch {
            print("Failed to mark listened: \(error)")
        }
    }
    
    func selectEpisode(_ episode: EpisodeRecord) async {
        await playerVm.selectEpisode(episode.objectId)
    }
    
    func episodeDownloadState(_ episode: EpisodeRecord) -> DownloadState {
        manageDownloadsUseCase.episodeState(episode: episode)
    }
}
