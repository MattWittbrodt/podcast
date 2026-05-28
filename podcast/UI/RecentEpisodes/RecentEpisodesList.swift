//
//  RecentEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI
import CoreData

struct RecentEpisodesList: View {
    @StateObject private var viewModel: RecentEpisodesViewModel
    
    // Global environment
    @EnvironmentObject private var themeManager: ThemeManager
        
    init(dataManager: DataManager,
         downloadManager: DownloadManager,
         refreshLibraryUseCase: RefreshLibraryUseCase,
         processManualDownloadUseCase: ProcessManualDownloadUseCase,
         finishEpisodeUseCase: FinishEpisodeUseCase,
         showFullPlayer: Binding<Bool>,
         playbackManager: PlaybackManager) {
                
        self._viewModel = StateObject(wrappedValue: RecentEpisodesViewModel(
            dataManager: dataManager,
            downloadManager: downloadManager,
            refreshLibraryUseCase: refreshLibraryUseCase,
            processManualDownloadUseCase: processManualDownloadUseCase,
            finishEpisodeUseCase: finishEpisodeUseCase,
            showFullPlayer: showFullPlayer,
            playbackManager: playbackManager,
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
        .alert(
            viewModel.activeAlert?.id ?? "Alert",
            isPresented: Binding(
                get: { viewModel.activeAlert != nil },
                set: { if !$0 { viewModel.activeAlert = nil } }
            )
        ) {
            if case .cellularDownload = viewModel.activeAlert {
                if let episode = viewModel.inFocusEpisode {
                    Button("Download Anyway") {
                        viewModel.startManualDownload(episode, manualOverride: true)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            Text("Selection an option")
        }
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
            ForEach(viewModel.unlistenedEpisodes, id: \.objectID) { episode in
                EpisodeListCard(episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActions(for: episode)
                    }
                    .onTapGesture {
                        viewModel.selectEpisode(episode)
                    }
            }
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }

    private func swipeActions(for episode: Episode) -> some View {
        
        HStack {
            Button(action: {
                viewModel.episodeListenedSwipeAction(episode)
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
