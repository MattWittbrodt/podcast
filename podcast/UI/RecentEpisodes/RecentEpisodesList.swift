//
//  RecentEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI
import CoreData

struct RecentEpisodesList: View {
    @Environment(RecentEpisodesViewModel.self) var viewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var activeAlert: AlertType?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    header
                    episodeList(viewModel: viewModel, in: geometry)
                }
                .padding(.horizontal)
            }
            .background(Color(themeManager.selectedTheme.secondaryColor))
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
    
    private func episodeList(viewModel: RecentEpisodesViewModel, in geometry: GeometryProxy) -> some View {
        List {
            ForEach(viewModel.unlistenedEpisodes, id: \.objectId) { episode in
                EpisodeListCard(
                    episode: episode,
                    downloadState: viewModel.episodeDownloadState(episode)
                )
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
        .background(themeManager.selectedTheme.secondaryColor)
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

#Preview {
    RecentEpisodesList()
        .environment(RecentEpisodesViewModel.preview)
        .environmentObject(ThemeManager())
}
