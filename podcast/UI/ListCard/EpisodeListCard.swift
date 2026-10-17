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
        Group {
            if let imgData = imageData, let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "waveform.badge.microphone")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 95, height: 95)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct EpisodeListCard: View {
    var episode: EpisodeRecord
    var downloadState: DownloadState
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            EpisodeListCardImage(imageData: episode.imgData)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.episodeTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(episode.podcastTitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                EpisodeMetadataView(
                    date: episode.formattedDate,
                    duration: episode.duration - Int16(episode.lastListened),
                    downloadState: downloadState
                )
            }
        }
        .padding()
    }
}

struct EpisodeMetadataView: View {
    let date: String
    let duration: Int16
    let downloadState: DownloadState
        
    var body: some View {
        HStack(alignment: .bottom) {
            Text(date)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(shortTime(seconds: duration))")
                .font(.callout)
                .padding(.leading, 3)
            
            DownloadStatusView(state: downloadState)
                .font(.callout)
        }
    }
}

// MARK: Previews
#Preview("Full Card - Placeholder") {
    let mockEpisode = EpisodeRecord.preview
    EpisodeListCard(episode: mockEpisode, downloadState: .downloaded)
}

#Preview("Metadata States") {
    VStack(spacing: 20) {
        EpisodeMetadataView(date: "Oct 9, 2026", duration: 3000, downloadState: .downloaded)
        
        EpisodeMetadataView(date: "Oct 8, 2026", duration: 1800, downloadState: .downloading)
        
        EpisodeMetadataView(date: "Oct 7, 2026", duration: 4500, downloadState: .notDownloaded)
    }
    .padding()
}
