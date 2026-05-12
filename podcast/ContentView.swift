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
    var useCaseProvider: UseCaseProvider
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                Tab("Home", systemImage: "house") {
                    RecentEpisodesList(updateEpisodes: useCaseProvider.makeRefreshLibraryUseCase().execute,
                                       showFullPlayer: $showFullPlayer)
                    .environmentObject(themeManager)
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                }
                Tab("Podcasts", systemImage: "books.vertical") {
                    PodcastList(showFullPlayer: $showFullPlayer)
                        .toolbar(.visible, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar) //<- here
                }
                Tab("Discover", systemImage: "magnifyingglass") {
                    SearcherView()
                        .environmentObject(themeManager)
                        .environmentObject(discoveryManager)
                        .toolbar(.visible, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                }
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                       .toolbar(.visible, for: .tabBar)
                       .toolbarBackground(.visible, for: .tabBar) //<- here
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
                    .environmentObject(settingsManager)
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
                .environmentObject(settingsManager)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                Task {
                    await useCaseProvider.makeRefreshLibraryUseCase().execute()
                }
            }
        }
    }
}

//#Preview {
//    ContentView()
//        .environmentObject(PlayerViewModel(context: PersistenceController.preview.container.viewContext))
//}
