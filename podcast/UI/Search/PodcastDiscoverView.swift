//
//  podcastIntro.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/15/25.
//

import SwiftUI

struct displayEpisode: View {
    var episode: PresentationEpisode
    
    var body: some View {
        VStack (alignment: .leading) {
            Text(episode.episodeTitle)
                .fontWeight(.semibold)
            HStack {
                Text(formatDate(time: episode.date()))
                Spacer()
                Text(episode.presentationDuration())
            }
            Text(episode.description())
                .lineLimit(3)
                .fontWeight(.light)
                .padding(.top, 5)
        }
    }
}

struct PodcastDiscoverView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let podcastDetail: PodcastDetailDestination
    let subscribeUseCase: SubscribeToPodcastUseCase
    
    init(podcastDetail: PodcastDetailDestination, useCase: SubscribeToPodcastUseCase) {
        self.podcastDetail = podcastDetail
        self.subscribeUseCase = useCase
    }
    
    var body: some View {
        VStack {
            podcastHeader
                .padding(20)
            Text(podcastDetail.podcast.podcast.description)
                .lineLimit(4)
            Button {
                Task {
                    await subscribeUseCase.execute(podcastDetail: podcastDetail)
                }
            }
            label: {
                Label("Subscribe", systemImage: "plus")
            }
            .padding()
            .tint(themeManager.selectedTheme.primaryColor)
            .buttonStyle(.bordered)
            episodeList
        }
    }
    
    private var podcastHeader: some View {
        HStack {
            if let url = URL(string: podcastDetail.podcast.imageLink()) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 75, height: 75)
            }
            VStack(alignment: .leading) {
                Text(podcastDetail.podcast.podcast.title)
                    .font(.headline)
                Text(podcastDetail.podcast.podcast.author)
                    .font(.subheadline)
            }
        }
    }
    
    private var episodeList: some View {
        NavigationStack {
            List(podcastDetail.channel.items) { episode in
                displayEpisode(episode: episode)
            }
        }
    }
}

//#Preview {
//    PodcastDiscoverView()
//        .environmentObject(DiscoveryManager.preview)
//        .environmentObject(ThemeManager())
//}
