//
//  podcastIntro.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/15/25.
//

import SwiftUI

struct PodcastDiscoverView: View {
    @EnvironmentObject private var discoveryManager: DiscoveryManager
    @State private var selectedEpisode: Episode?
    @State private var podcastImg: UIImage?
    
    var body: some View {
        VStack {
            VStack {
                Text("\(String(describing: discoveryManager.selectedPodcast?.podcast.title))").font(.headline)
                Text("\(String(describing: discoveryManager.selectedPodcast?.podcast.author))").font(.subheadline)
                Button {
                    discoveryManager.subscribeToPodcast()
                }
                label: {
                    Label("Subscribe", systemImage: "plus")
                }
                .padding()
            }
            Text("\(String(describing: discoveryManager.selectedPodcast?.podcast.description))")
                .lineLimit(3)
            episodeList
        }
    }
    
    private var episodeList: some View {
        NavigationStack {
            List(discoveryManager.rssChannel?.items ?? []) { episode in
                Text(episode.episodeTitle)
            }
        }
    }
}

//#Preview {
//    PodcastDiscoverView()
//        .environmentObject(DiscoveryManager.preview)
//}
