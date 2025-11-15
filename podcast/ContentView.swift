//
//  ContentView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/8/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var playerManager: PlayerViewModel
    @EnvironmentObject private var persistenceManagerOld: PersistenceManagerOld
    @StateObject var themeManager = ThemeManager()
    
    @State private var selectedEpisode: Episode?
    @State private var showFullScreenPlayer = false
    @State private var showMiniPlayer = false
    //New
    @StateObject var discoveryManager: DiscoveryManager
    @StateObject var dataManager: DataManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                RecentEpisodesList<PlayerViewModel>()
                    .environmentObject(themeManager)
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                
                PodcastList<PlayerViewModel>()
                    .environmentObject(playerManager)
                    .environmentObject(themeManager)
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "books.vertical")
                        Text("Podcasts")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
                
                SearcherView()
                    .environmentObject(themeManager)
                    .environmentObject(dataManager)
                    .environmentObject(discoveryManager)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
     
                BookmarksView<PlayerViewModel>()
                    .tabItem {
                        Image(systemName: "bookmark")
                        Text("Bookmarks")
                    }
                    .environmentObject(themeManager)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar) //<- here
                    .toolbarBackground(Color(themeManager.selectedTheme.secondoryColor), for: .tabBar)
            }
            .accentColor(Color(themeManager.selectedTheme.primaryColor))
            
            if playerManager.currentEpisode != nil {
                MiniPlayerView<PlayerViewModel>()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 ? 20 : 0)
                    .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $playerManager.showFullPlayer) {
            if playerManager.currentEpisode != nil {
                Player<PlayerViewModel>()
                    .environmentObject(playerManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

//#Preview {
//    ContentView()
//        .environmentObject(PlayerViewModel(context: PersistenceController.preview.container.viewContext))
//}
