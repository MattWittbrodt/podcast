//
//  RecentEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI
import CoreData

struct RecentEpisodesList: View {
    @State private var viewModel: RecentEpisodesViewModel
    
    // Global environment
    @EnvironmentObject private var themeManager: ThemeManager
    
    var activeAlert: AlertType?
        
    init(container: AppContainer) {
                
        self._viewModel = State(wrappedValue: RecentEpisodesViewModel(
            dataManager: container.dataManager,
            downloadManager: container.downloadManager,
            refreshLibraryUseCase: container.refreshLibraryUseCase,
            processManualDownloadUseCase: container.processManualDownloadUseCase,
            setEpisodeAsListenedUseCase: container.setEpisodeAsListenedUseCase,
            //showFullPlayer: showFullPlayer,
            playbackManager: container.playbackManager,
            playerViewModel: container.playerViewModel,
            loadEpisodesUseCase: container.loadEpisodeUseCase,
        ))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    header
                    episodeList(in: geometry)
                }
                    .padding(.horizontal)
                }
                .background(Color(themeManager.selectedTheme.secondoryColor))
                .refreshable {
                    await viewModel.refresh()
                }
        }
//        .alert(
//            viewModel.activeAlert?.id ?? "Alert",
//            isPresented: Binding(
//                get: { viewModel.activeAlert != nil },
//                set: { if !$0 { viewModel.activeAlert = nil } }
//            )
//        ) {
//            if case .cellularDownload = viewModel.activeAlert {
//                if let episode = viewModel.inFocusEpisode {
//                    Button("Download Anyway") {
//                        viewModel.startManualDownload(episode, manualOverride: true)
//                    }
//                }
//                Button("Cancel", role: .cancel) {}
//            }
//        } message: {
//            Text("Selection an option")
//        }
    }
    
    private var header: some View {
        HStack {
            Text("Recent Episodes")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
            Text("Unlistened: \(viewModel.unlistenedEpisodes.count)")
                .font(.headline)
                .fontWeight(.light)
        }
        .foregroundStyle(themeManager.selectedTheme.primaryColor)
    }
    
    private func episodeList(in geometry: GeometryProxy) -> some View {
        List {
            ForEach(viewModel.unlistenedEpisodes, id: \.objectId) { episode in
                EpisodeListCard(episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActions(for: episode)
                    }
                    .onTapGesture {
                        Task {
                            await viewModel.selectEpisode(episode)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
        .task { await viewModel.loadEpisodes() }
    }

    private func swipeActions(for episode: EpisodeRecord) -> some View {
        
        HStack {
            Button(action: {
                Task {
                    await viewModel.episodeListenedSwipeAction(episode)
                }
            }) {
                Label("Listened", systemImage: "tray.fill")
            }
            .tint(.orange)
            
            Button(action: {
                viewModel.manualDownloadSwipeAction(episode)
            })
            {
                Label("Download", systemImage: "square.and.arrow.down.fill")
            }
            .tint(.green)
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
