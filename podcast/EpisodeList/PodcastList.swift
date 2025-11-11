//
//  PodcastList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/25.
//

import SwiftUI

struct PodcastList<ViewModel: PlayerViewModelProtocol>: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var playerManager: ViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    @FetchRequest(fetchRequest: Podcast.allSaved())
    
    private var podcasts
    
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
            podcastListContent()
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }
    
    private func podcastListContent() -> some View {
        ForEach(podcasts) { podcast in
            NavigationLink {
                LazyEpisodeView<ViewModel>(podcast: podcast)
            } label: {
                PodcastListCard(
                    title: podcast.title,
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
    
    private func swipeActions(for podcast: Podcast) -> some View {
        HStack {  // Using HStack instead of Group provides better type inference
            Button(action: {
                Task { @MainActor in
                    //episode.listened = true
                    //await viewModel.loadRecentEpisodes()
                    Podcast.delete(podcast: podcast)
                }
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

struct LazyEpisodeView<ViewModel: PlayerViewModelProtocol>: View {
    let podcast: Podcast
    @State private var episodes: [Episode] = []
    @State private var isLoading = false
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EpisodeList<ViewModel>(podcast: podcast, episodeList: episodes)
            }
        }
        .task {
            await loadEpisodes()
        }
    }
    
    private func loadEpisodes() async {
        isLoading = true
        episodes = await fetchEpisodes(for: podcast)
        isLoading = false
    }
    
    private func fetchEpisodes(for podcast: Podcast) async -> [Episode] {
        //let context = self.persistenceManager.context
        return await self.persistenceManager.viewContext.perform { //context.perform {
            let request = Episode.fetchRequest()
            request.predicate = NSPredicate(format: "podcast == %@", podcast)
            request.sortDescriptors = [NSSortDescriptor(key: "publishedDate", ascending: false)]
            return (try? self.persistenceManager.viewContext.fetch(request)) ?? []
        }
    }
}


//#Preview {
//    let previewContainer = PersistenceController.preview.container
//    
//    PodcastList<MockPlayerViewModel>()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//        .environmentObject(MockPlayerViewModel(context: previewContainer.viewContext))
//        .environmentObject(ThemeManager())
//}
