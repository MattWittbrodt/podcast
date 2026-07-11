//
//  ListCard.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/23/25.
//

import SwiftUI

struct EpisodeListCardImage: View {
    var imageData: Data?
    
    var body: some View {
        if let imgData = imageData {
            Image(uiImage: UIImage(data: imgData) ?? UIImage())
                .resizable()
                .frame(width: 100, height: 100, alignment: .topLeading)
                .cornerRadius(20)
        } else {
            Image(systemName: "waveform.badge.microphone")
                .resizable()
                .frame(width: 75, height: 75)
                .foregroundColor(.gray)
        }
    }
}

struct EpisodeListCard: View {
    @Environment(RecentEpisodesViewModel.self) private var viewModel
    
    var episode: EpisodeRecord
    @State private var downloadState: DownloadState = .notDownloaded
    
    var body: some View {
        let downloadState = viewModel.episodeDownloadState(episode)
        HStack{
            EpisodeListCardImage(imageData: episode.imgData)
            Spacer()
            VStack(alignment: .leading) {
                Text("\(episode.episodeTitle)")
                    .lineLimit(2)
                    .font(.headline)
                    .padding(.bottom, 2)
                Text("\(episode.podcastTitle)")
                    .lineLimit(1)
                    .font(.subheadline)
                    .opacity(0.7)
                HStack{
                    Text("\(episode.formattedDate)")
                    Spacer()
                    Text("\(shortTime(seconds: episode.duration-Int16(episode.lastListened)))")
                        .padding(.leading,3)
                    DownloadStatusView(state: downloadState)
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    
//    EpisodeListCard(episode: RSSEpisode.example)
//}
