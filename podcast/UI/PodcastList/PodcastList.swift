////
////  PodcastList.swift
////  podcast
////
////  Created by Matt Wittbrodt on 5/27/25.
////
//
import SwiftUI

struct PodcastList: View {
    @State private var viewModel: PodcastListViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var showFullPlayer: Bool
    
    private let container: AppContainer
    
    init(
        container: AppContainer,
        showFullPlayer: Binding<Bool>
    ) {
        self.container = container
        self._showFullPlayer = showFullPlayer
        self._viewModel = State(wrappedValue: PodcastListViewModel(podcastRepository: container.podcastRepository))
    }
        
    var body: some View {
        NavigationStack{
            content
                .background(Color(themeManager.selectedTheme.secondoryColor))
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                header
                podcastList(in: geometry)
            }
            .padding(.horizontal)
        }
    }
    
    private func podcastList(in geometry: GeometryProxy) -> some View {
        List {
            ForEach(viewModel.podcasts, id: \.objectId) { podcast in
                NavigationLink {
                   PodcastView(
                    podcast: podcast,
                    container: container,
                    //showFullPlayer: $showFullPlayer,
                   )
                } label: {
                    PodcastListCard(
                        title: podcast.podcastTitle,
                        author: podcast.author,
                        image: podcast.imageUrl ?? ""
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActions(for: podcast)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }
    
    private func swipeActions(for podcast: PodcastRecord) -> some View {
        HStack {
            Button(action: {
                viewModel.unsuscribeFromPodcast(podcast)
            }) {
                Label("Unsuscribe", systemImage: "tray.fill")
            }
            .tint(.red)
        }
    }
    
    private var header: some View {
        HStack {
            Text("All Podcasts")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundStyle(themeManager.selectedTheme.primaryColor)
        .background(Color(themeManager.selectedTheme.secondoryColor))
    }
}
//
//
////#Preview {
////    @Previewable @State var showFullPlayer: Bool = false
////    let dm = DataManager.preview
////    let dlManager = DownloadManager()
////    let _ = print("here2: \(dm.podcasts.count)")
////    let sm = SettingsManager(dataManager: dm)
////    let pbM = PlaybackManager(downloadManager: dlManager, dataManager: dm, settingsManager: sm)
////    
////    PodcastList(showFullPlayer: $showFullPlayer)
////        .environmentObject(dm)
////        .environmentObject(pbM)
////        .environmentObject(DownloadManager())
////        .environmentObject(ThemeManager())
////}
