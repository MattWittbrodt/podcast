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
            Image(uiImage: UIImage(data: imgData)!)
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
    // Local state to hold the state received from the publisher
    @State private var downloadState: DownloadState = .notDownloaded
    
    var body: some View {
        HStack{
            //EpisodeListCardImage(imageData: episode.episode.imageData ?? episode.episode.podcastImgData)
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
                        .padding(.leading,3)
                    Spacer()
                    Text("\(shortTime(seconds: episode.episodeDuration-Int16(episode.lastListenedTime)))")
                        .padding(.leading,3)
                    DownloadStatusView(state: downloadState)
                }
            }
        }
        .padding()
        .onReceive(
            downloadManager.downloadStatePublisher(for: episode.objectID,
                                                   initialDownloadState: downloadManager.downloadFileExists(for: episode))) { state in
            //print("✴️ Download state changed for \(String(describing: episode.title)): \(state)")
            // Update the local @State, triggering a view refresh
            downloadState = state
        }
    }
    
}

//#Preview {
//    
//    EpisodeListCard(episode: RSSEpisode.example)
//}
