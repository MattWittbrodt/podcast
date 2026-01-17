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
    @EnvironmentObject private var discoveryManager: DiscoveryManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            podcastHeader
                .padding(20)
            Text(discoveryManager.selectedPodcast?.podcast.description ?? "Missing Description")
                .lineLimit(4)
            Button {
                discoveryManager.subscribeToPodcast()
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
            if let url = URL(string: discoveryManager.selectedPodcast?.podcast.imageLink() ?? "") {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 75, height: 75)
            }
            VStack(alignment: .leading) {
                Text(discoveryManager.selectedPodcast?.podcast.title ?? "Missing Title")
                    .font(.headline)
                Text(discoveryManager.selectedPodcast?.podcast.author ?? "Missing Author")
                    .font(.subheadline)
            }
        }
    }
    
    private var episodeList: some View {
        NavigationStack {
            List(discoveryManager.rssChannel?.items ?? []) { episode in
                displayEpisode(episode: episode)
            }
        }
    }
}

#Preview {
    PodcastDiscoverView()
        .environmentObject(DiscoveryManager.preview)
        .environmentObject(ThemeManager())
}
