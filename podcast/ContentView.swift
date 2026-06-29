//
//  ContentView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/8/25.
//
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(AppContainer.self) var container: AppContainer
        
    @StateObject var themeManager = ThemeManager()
    
    @State private var selectedEpisode: Episode?
    @State private var showFullPlayer = false
    @State private var showMiniPlayer = false
    @State private var updateMessage = ""
    @State private var selectedTab = 0
      
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                Tab("Home", systemImage: "house") {
                    RecentEpisodesList(
                        container: container,
                    )
                    .environmentObject(themeManager)
                    //.toolbar(.visible, for: .tabBar)
                    //.toolbarBackground(.visible, for: .tabBar)
                }
                Tab("Podcasts", systemImage: "books.vertical") {
                    PodcastList(
                        container: container,
                        showFullPlayer: $showFullPlayer
                    )
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                }
                Tab("Discover", systemImage: "magnifyingglass") {
                    SearcherView(
                        discoveryManager: container.discoveryManager,
                        useCase: container.subscribeToPodcastUseCase
                    )
                    .toolbar(.visible, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                }
                Tab("Settings", systemImage: "gear") {
                    SettingsView(useCase: container.manageSettingsUseCase)
                       .toolbar(.visible, for: .tabBar)
                       .toolbarBackground(.visible, for: .tabBar)
                }
            }
            .environment(container.dataManager)
            .environment(container.playbackManager)
            .environmentObject(container.downloadManager)
            .environmentObject(themeManager)
            .accentColor(Color(themeManager.selectedTheme.primaryColor))
            
            if container.playbackManager.currentEpisode != nil {
                MiniPlayerView(showFullPlayer: $showFullPlayer)
                    .environment(container.playbackManager)
                    .environment(container.playerViewModel)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 ? 20 : 0)
                    .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: Bindable(container.playerViewModel).showFullPlayer) {
            Player(viewModel: container.playerViewModel)
                .environmentObject(themeManager)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                Task {
                    await container.refreshLibraryUseCase.execute(notifyUser: false)
                }
            }
        }
    }
}
