//
//  ContentView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/8/25.
//
import SwiftUI

struct ContentView: View {
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
    
    func updateEpisodes() async {
        updateMessage = "getting new episodes..."
        let newEpisodes = await feedService.updateAllSubscribedPodcasts()
        
        // Updating chapters
        updateMessage = "updating episodes with chapters"
        await dataManager.updateEpisodesWithChapters()
        updateMessage = "updated episodes with chapters. now handling episodes"
        
        // Continue handling episodes
        dataManager.handleNewEpisodes(episodes: newEpisodes)
        updateMessage = "starting download"
        for episode in newEpisodes {
            downloadManager.startDownload(for: episode)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                RecentEpisodesList(updateEpisodes: updateEpisodes,
                                   showFullPlayer: $showFullPlayer,
                                   updateMessage: $updateMessage)
                    .environmentObject(themeManager)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                
                PodcastList(showFullPlayer: $showFullPlayer)
                    .tabItem {
                        Image(systemName: "books.vertical")
                        Text("Podcasts")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                
                SearcherView()
                    .environmentObject(themeManager)
                    .environmentObject(discoveryManager)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
     
//                BookmarksView()
//                    .tabItem {
//                        Image(systemName: "bookmark")
//                        Text("Bookmarks")
//                    }
//                    .environmentObject(themeManager)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
            }
            .environmentObject(dataManager)
            .environmentObject(playbackManager)
            .environmentObject(downloadManager)
            .environmentObject(themeManager)
            .accentColor(Color(themeManager.selectedTheme.primaryColor))
            .onAppear {
                Task {
                    await updateEpisodes()
                }
            }
            
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
        }
    }
}

//#Preview {
//    ContentView()
//        .environmentObject(PlayerViewModel(context: PersistenceController.preview.container.viewContext))
//}
