//
//  PodcastView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/26/25.
//

import SwiftUI

struct PodcastView: View {
    
    @StateObject private var viewModel: PodcastViewModel
    let podcast: Podcast
    
    init(
        appDependencies: AppDependencies,
        episodeRepository: EpisodeRepository,
        podcast: Podcast,
        showFullPlayer: Binding<Bool>
    ) {
        self.podcast = podcast
        self._viewModel = StateObject(wrappedValue: PodcastViewModel(
            appDependencies: appDependencies,
            podcast: podcast,
            episodeRepository: episodeRepository,
            showFullPlayer: showFullPlayer
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
            ForEach(viewModel.episodes, id: \.id) { episode in
                EpisodeListCard(episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActions(for: episode)
                    }
                    .onTapGesture {
                        viewModel.handleEpisodeSelection(episode)
                    }
            }
        }
        .task {
            await viewModel.getAllEpisodes()
        }
        
    }
    
    private func swipeActions(for episode: Episode) -> some View {
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
