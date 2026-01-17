//
//  PodcastList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI

struct PodcastList: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var downloadManager: DownloadManager
    @Binding var showFullPlayer: Bool
        
    var body: some View {
        NavigationStack{
            content
                .background(Color(themeManager.selectedTheme.secondoryColor))
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                header
                podcastList(in: geometry)
            }
            .padding(.horizontal)
        }
    }
    
    private func podcastList(in geometry: GeometryProxy) -> some View {
        List {
            podcastListContent()
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }
    
    private func podcastListContent() -> some View {
        ForEach(dataManager.podcasts, id: \.id) { podcast in
            NavigationLink {
               PodcastView(podcast: podcast, showFullPlayer: $showFullPlayer)
            } label: {
                PodcastListCard(
                    title: podcast.title,
                    author: podcast.author,
                    image: podcast.imageUrl ?? ""
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    swipeActions(for: podcast)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }
    
    private func swipeActions(for podcast: Podcast) -> some View {
        HStack {
            Button(action: {
                Task { @MainActor in
                    Podcast.delete(podcast: podcast)
                    self.dataManager.saveMainContext()
                    self.dataManager.refreshEpisodes()
                    self.dataManager.refreshPodcasts()
                }
            }) {
                Label("Unsuscribe", systemImage: "tray.fill")
            }
            .tint(.red)
        }
    }
    
    private var header: some View {
        HStack {
            Text("All Podcasts")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundStyle(themeManager.selectedTheme.primaryColor)
        .background(Color(themeManager.selectedTheme.secondoryColor))
    }
}


#Preview {
    @Previewable @State var showFullPlayer: Bool = false
    let dm = DataManager.preview
    
    PodcastList(showFullPlayer: $showFullPlayer)
        .environmentObject(dm)
        .environmentObject(DownloadManager(dataManager: dm))
        .environmentObject(ThemeManager())
}
