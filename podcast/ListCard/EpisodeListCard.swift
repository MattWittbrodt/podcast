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
    @ObservedObject var episode: ObservableDisplayEpisode
    
    var body: some View {
        HStack{
            EpisodeListCardImage(imageData: episode.episode.imageData ?? episode.episode.podcastImgData)
            Spacer()
            VStack(alignment: .leading) {
                Text("\(episode.episode.episodeTitle)")
                    .lineLimit(2)
                    .font(.headline)
                    .padding(.bottom, 2)
                Text("\(episode.episode.podcastTitle)")
                    .lineLimit(1)
                    .font(.subheadline)
                    .opacity(0.7)
                HStack{
                    Text("\(episode.episode.formattedDate)")
                        .padding(.leading,3)
                    Spacer()
                    Text("\(shortTime(seconds: episode.episode.episodeDuration-Int16(episode.episode.lastListenedTime)))")
                        .padding(.leading,3)
                    Image(systemName: episode.episode.isDownloaded ? "arrow.down.circle.fill":"arrow.down.circle")
                        .padding(.trailing, 3)
                        .opacity(0.60)
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
