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
    @EnvironmentObject var downloadManager: DownloadManager
    @ObservedObject var episode: Episode
    @State private var downloadState: DownloadState = .notDownloaded
    
    var body: some View {
        HStack{
            EpisodeListCardImage(imageData: episode.getImageData())
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
                    Text("\(shortTime(seconds: episode.episodeDuration-Int16(episode.lastListened)))")
                        .padding(.leading,3)
                    DownloadStatusView(state: downloadState)
                }
            }
        }
        .padding()
        .onReceive(
            downloadManager.downloadStatePublisher(for: episode.objectID,
                                                   fileAlreadyExists: downloadManager.downloadFileExists(for: episode))) { state in
            downloadState = state
        }
    }
}

//#Preview {
//    
//    EpisodeListCard(episode: RSSEpisode.example)
//}
