//
//  RecentEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI
import CoreData

struct RecentEpisodesList: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var downloadManager: DownloadManager
    @EnvironmentObject private var playbackManager: PlaybackManager
    
    @Binding var showFullPlayer: Bool
    @Binding var updateMessage: String
    
    let updateEpisodes: () async -> Void
    
    init(updateEpisodes: @escaping () async -> Void, showFullPlayer: Binding<Bool>, updateMessage: Binding<String>) {
        self.updateEpisodes = updateEpisodes
        self._showFullPlayer = showFullPlayer
        self._updateMessage = updateMessage
    }
    
    var body: some View {
        NavigationStack {
            content
                .background(Color(themeManager.selectedTheme.secondoryColor))
                .refreshable {
                    await updateEpisodes()
                }
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                header
                Text(updateMessage)
                episodeList(in: geometry)
            }
            .padding(.horizontal)
        }
    }
    
    private var header: some View {
        HStack {
            Text("Recent Episodes")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
            Text("Unlistened: \(dataManager.unlistenedEpisodes.count)")
                .font(.headline)
                .fontWeight(.light)
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
        ForEach(dataManager.unlistenedEpisodes, id: \.objectID) { episode in
            EpisodeListCard(episode: episode)
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
                dataManager.markEpisodeAsListened(episode)
            }) {
                Label("Listened", systemImage: "tray.fill")
            }
            .tint(.orange)
            
            Button(action: {
                Task {
                    downloadManager.startDownload(for: episode)
                }}) {
                Label("Download", systemImage: "square.and.arrow.down.fill")
            }
            .tint(.green)
        }
    }
    
    private func handleEpisodeSelection(_ episode: Episode) {
        Task { @MainActor in
            showFullPlayer = true
            playbackManager.loadEpisodeAndPlaylist(
                episode: episode,
                playlist: dataManager.unlistenedEpisodes
            )
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
