//
//  ContentView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/8/25.
//
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var themeManager = ThemeManager()
    
    @State private var selectedEpisode: Episode?
    @State private var showFullPlayer = false
    @State private var showMiniPlayer = false
    @State private var updateMessage = ""
    
    @StateObject var discoveryManager: DiscoveryManager
    @StateObject var downloadManager: DownloadManager
    @StateObject var dataManager: DataManager
    @StateObject var feedService: PodcastFeedService
    @StateObject var playbackManager: PlaybackManager
    @StateObject var settingsManager: SettingsManager
    
    func updateEpisodes() async {
        let newEpisodes = await feedService.updateAllSubscribedPodcasts()
        
        // Updating chapters
        await dataManager.updateEpisodesWithChapters()
        
        // Continue handling episodes
        dataManager.handleNewEpisodes(episodes: newEpisodes)
        
        // Checking for unlistened episodes that are not downloaded
        let groupedByPodcast = Dictionary(grouping: dataManager.unlistenedEpisodes, by: { $0.podcast?.title ?? "Unknown Podcast" })

        // Map over each group to sort and take the top 3
        let possibleDownloads = groupedByPodcast.mapValues { episodes in
            episodes
                .sorted { $0.publishedDate ?? .distantPast > $1.publishedDate ?? .distantPast}
                .prefix(Int(settingsManager.numDownloads))
        }.values.flatMap { $0 }
        
        // Passing through start download. For possibleDownloads, startDownload will simply return if already downloaded
        for episode in newEpisodes + possibleDownloads {
            downloadManager.startDownload(for: episode)
        }
        
        // For unlistened episodes not in the download list, remove download to save space on device
        for episode in dataManager.unlistenedEpisodes {
            if !possibleDownloads.contains(episode) {
                downloadManager.removeDownload(for: episode)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                Tab("Home", systemImage: "house") {
                    RecentEpisodesList(updateEpisodes: updateEpisodes,
                                       showFullPlayer: $showFullPlayer)
                    .environmentObject(themeManager)
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                }
                Tab("Podcasts", systemImage: "books.vertical") {
                    PodcastList(showFullPlayer: $showFullPlayer)
                        .toolbar(.visible, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar) //<- here
                        .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                }
                Tab("Discover", systemImage: "magnifyingglass") {
                    SearcherView()
                        .environmentObject(themeManager)
                        .environmentObject(discoveryManager)
                        .toolbar(.visible, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar) //<- here
                        .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                }
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                       .toolbar(.visible, for: .tabBar)
                       .toolbarBackground(.visible, for: .tabBar) //<- here
                       .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                }
//

//     
////                BookmarksView()
////                    .tabItem {
////                        Image(systemName: "bookmark")
////                        Text("Bookmarks")
////                    }
////                    .environmentObject(themeManager)
//                
//
            }
            .environmentObject(dataManager)
            .environmentObject(playbackManager)
            .environmentObject(downloadManager)
            .environmentObject(themeManager)
            .environmentObject(settingsManager)
            .accentColor(Color(themeManager.selectedTheme.primaryColor))
            
            if playbackManager.currentEpisode != nil {
                MiniPlayerView(showFullPlayer: $showFullPlayer)
                    .environmentObject(playbackManager)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 ? 20 : 0)
                    .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showFullPlayer) {
            Player()
                .environmentObject(playbackManager)
                .environmentObject(themeManager)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                Task {
                    await updateEpisodes()
                }
            }
        }
    }
}

//#Preview {
//    ContentView()
//        .environmentObject(PlayerViewModel(context: PersistenceController.preview.container.viewContext))
//}
