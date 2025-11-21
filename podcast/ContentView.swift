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
    //New
    @StateObject var discoveryManager: DiscoveryManager
    @StateObject var downloadManager: DownloadManager
    @StateObject var dataManager: DataManager
    @StateObject var feedService: PodcastFeedService
    @StateObject var playbackManager: PlaybackManager
    
    func updateEpisodes() async {
        let newEpisodes = await feedService.updateAllSubscribedPodcasts()
        dataManager.handleNewEpisodes(episodes: newEpisodes)
        for episode in newEpisodes {
            downloadManager.startDownload(for: episode)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                RecentEpisodesList(updateEpisodes: updateEpisodes,
                                   showFullPlayer: $showFullPlayer)
                    .environmentObject(themeManager)
                    .environmentObject(downloadManager)
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                
                PodcastList()
                    .environmentObject(themeManager)
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
