//
//  PodcastView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/26/25.
//

import SwiftUI

struct PodcastView: View {
    @State private var viewModel: PodcastViewModel
    @Environment(PlayerViewModel.self) var playerVM
    let podcast: PodcastRecord
    
    init(podcast: PodcastRecord, container: AppContainer) {
        self.podcast = podcast
        self._viewModel = State(wrappedValue: PodcastViewModel(
            dataManager: container.dataManager,
            downloadManager: container.downloadManager,
            playbackUseCase: container.playbackUseCase,
            podcast: podcast,
            podcastRepository: container.podcastRepository,
            loadEpisodeUseCase: container.loadEpisodeUseCase,
            //showFullPlayer: showFullPlayer
        ))
    }
    
    var body: some View {
        Menu("Options") {
            Button("Mark All As Listened", systemImage: "tray.fill") {
                viewModel.markAllListened()
            }
            Button("Share", systemImage: "square.and.arrow.up") {
                // Handle share
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                // Handle delete
            }
        }
        List {
            ForEach(viewModel.episodes, id: \.objectId) { episode in
                EpisodeListCard(episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActions(for: episode)
                    }
                    .onTapGesture {
                        Task {
                            await playerVM.selectEpisode(episode.objectId)
                        }
                    }
            }
        }
        .task {
            await viewModel.getAllEpisodes()
        }
        
    }
    
    private func swipeActions(for episode: EpisodeRecord) -> some View {
        HStack {
            Button(action: {
                Task {
                    viewModel.startDownloadForEpisode(episode)
                }}) {
                Label("Download", systemImage: "square.and.arrow.down.fill")
            }
            .tint(.green)
            
            Button(action: {
                Task {
                    viewModel.markEpisodeAsUnlistened(episode)
                }}) {
                Label("Mark as Unlistened", systemImage: "circle.fill")
            }
                .tint(.blue)
        }
    }
}

//#Preview {
//    @Previewable @State var showFullPlayer: Bool = false
//    let dm = DataManager.preview
//    let _ = print("here: \(dm.podcasts.count)")
//    let dlManager = DownloadManager()
//    
//    let sm = SettingsManager(dataManager: dm)
//    let pbM = PlaybackManager(downloadManager: dlManager, dataManager: dm, settingsManager: sm)
//    
//    let samplePodcast = Podcast.createSample(context: dm.persistence.viewContext)
//    
//    PodcastView(podcast: samplePodcast, showFullPlayer: $showFullPlayer)
//        .environmentObject(dm)
//        .environmentObject(pbM)
//        .environmentObject(dlManager)
//        .environmentObject(ThemeManager())
//
//}
