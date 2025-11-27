//
//  PodcastView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/26/25.
//

import SwiftUI

struct PodcastView: View {
    let podcast: Podcast
    @State private var episodes: [Episode] = []
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var downloadManager: DownloadManager
    @EnvironmentObject private var playbackManager: PlaybackManager
    @Binding var showFullPlayer: Bool

    var body: some View {
        List {
            ForEach(episodes, id: \.id) { episode in
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
        .onAppear {
            do {
                episodes = try self.dataManager.getEpisodesForPodcast(for: podcast)
            } catch {
                print("Cannot fetch episodes")
            }
        }
    }
    
    private func swipeActions(for episode: Episode) -> some View {
        HStack {
            Button(action: {
                Task {
                    downloadManager.startDownload(for: episode)
                }}) {
                Label("Download", systemImage: "square.and.arrow.down.fill")
            }
            .tint(.green)
            
            Button(action: {
                Task {
                    dataManager.markEpisodeAsUnlistened(episode)
                }}) {
                Label("Mark as Unlistened", systemImage: "circle.fill")
            }
                .tint(.blue)
        }
    }
    
    private func handleEpisodeSelection(_ episode: Episode) {
        Task { @MainActor in
            showFullPlayer = true
            playbackManager.startPlayingEpisode(episode: episode)
        }
    }
}

//#Preview {
//    PodcastView()
//}
