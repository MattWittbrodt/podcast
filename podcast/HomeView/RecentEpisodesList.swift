//
//  RecentEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI
import CoreData

struct RecentEpisodesList<ViewModel: PlayerViewModelProtocol>: View {
    //@State private var viewModel = RecentEpisodesViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var playerManager: ViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            content
                .background(Color(themeManager.selectedTheme.secondoryColor))
//                .onAppear {
//                    Task {
//                        viewModel.setup(persistenceManager: persistenceManager)
//                        await viewModel.loadRecentEpisodes()
//                        await viewModel.updatePodcasts()
//                    }
//                }
//                .refreshable {
//                    await viewModel.updatePodcasts()
//                }
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                header
                episodeList(in: geometry)
            }
            .padding(.horizontal)
        }
    }
    
    private var header: some View {
        HStack {
            //Text(playerManager.message)
            Text("Recent Episodes")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
//            Text("Unlistened: \(viewModel.episodes.count)")
//                .font(.headline)
//                .fontWeight(.light)
            
        }
        .foregroundStyle(themeManager.selectedTheme.primaryColor)
    }
    
    private func episodeList(in geometry: GeometryProxy) -> some View {
        List {
            episodeListContent()
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }

    private func episodeListContent() -> some View {
        ForEach(dataManager.unlistenedEpisodes) { episode in
            EpisodeListCard(episode: ObservableDisplayEpisode(episode: episode))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    swipeActions(for: episode)
                }
                .onTapGesture {
                    handleEpisodeSelection(episode)
                }
        }
    }

    private func swipeActions(for episode: Episode) -> some View {
        HStack {  // Using HStack instead of Group provides better type inference
            Button(action: {
                Task { @MainActor in
                    episode.listened = true
//                    await viewModel.loadRecentEpisodes()
                }
            }) {
                Label("Listened", systemImage: "tray.fill")
            }
            .tint(.orange)
            
            Button(action: {
                Task {
//                    await viewModel.swipeDownload(episode)
//                    await viewModel.loadRecentEpisodes()
                }}) {
                Label("Download", systemImage: "square.and.arrow.down.fill")
            }
            .tint(.green)
        }
    }
    
    private func handleEpisodeSelection(_ episode: Episode) {
        Task { @MainActor in
            await playerManager.setupPlayer(episode: episode)
            playerManager.playPause(alwaysPlay: true)
            playerManager.showFullPlayer = true
        }
    }
}

//#Preview {
//
//    let previewContainer = PersistenceController.preview.container
//
//    RecentEpisodesList<MockPlayerViewModel>()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//        .environmentObject(MockPlayerViewModel(context: previewContainer.viewContext))
//        .environmentObject(ThemeManager())
//}
