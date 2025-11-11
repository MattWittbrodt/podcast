//
//  podcastIntro.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/15/25.
//

import SwiftUI

struct IntroHeader: View {
    var podcast: PodcastInfo
    @State var image: UIImage?
    @ObservedObject var viewModel: PodcastIntroViewModel
    
    var body: some View {
        HStack {
            if let imageData = viewModel.imageData {
                let i = UIImage(data: imageData)!
                Image(uiImage: i)
                    .resizable()
                    .frame(width: 144, height: 144)
            }
            VStack {
                Text("\(podcast.title)").font(.headline)
                Text("\(podcast.author)").font(.subheadline)
                Button {
                    viewModel.subscribeToPodcast()
                }
                label: {
                    Label("Subscribe", systemImage: "plus")
                }
                .padding()
            }
        }
    }
}

struct IntroEpisodeList: View {
    var episodes: [RSSEpisode]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(episodes, id: \.episodeTitle) { episode in
                    EpisodeListCard(episode: ObservableDisplayEpisode(episode: episode))
//                        .onTapGesture {
//                            selectedEpisode = episode
//                        }
                }
            }
        }
    }
}

struct PodcastIntro: View {
    //@Environment(\.managedObjectContext) var context
    @EnvironmentObject private var persistenceManager: PersistenceManager
    var podcast: PodcastInfo
    @StateObject private var viewModel: PodcastIntroViewModel
    @State private var selectedEpisode: Episode?
    @State private var podcastImg: UIImage?
    
    init(podcast: PodcastInfo) {
        self.podcast = podcast
        self._viewModel = StateObject(wrappedValue: PodcastIntroViewModel(
            podcastUrl: podcast.url
        ))
    }
    
    var body: some View {
        VStack {
            IntroHeader(podcast: podcast, viewModel: viewModel)
            Text(podcast.description)
                .lineLimit(3)
            IntroEpisodeList(episodes: viewModel.episodes)
        }
        .onAppear {
            Task {
                viewModel.setContext(persistenceManager.viewContext)
                await viewModel.fetchPodcastData()
            }
        }
    }
}

#Preview {
    PodcastIntro(podcast: PodcastInfo.previewExample)
}
