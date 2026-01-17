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
    
    func updateEpisodes() async {
        let newEpisodes = await feedService.updateAllSubscribedPodcasts()
        
        // Updating chapters
        await dataManager.updateEpisodesWithChapters()
        
        // Continue handling episodes
        dataManager.handleNewEpisodes(episodes: newEpisodes)
        for episode in newEpisodes {
            downloadManager.startDownload(for: episode)
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
            print("\(oldValue) - \(newValue)")
            if newValue == .active {
                Task {
                    print("here")
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
