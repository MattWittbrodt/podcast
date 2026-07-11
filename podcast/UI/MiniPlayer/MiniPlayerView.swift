//
//  MiniPlayerView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/20/25.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlayerViewModel.self) var playerViewModel
    
    var body: some View {
        if let episode = playerViewModel.currentEpisode {
            Button(action: {
                playerViewModel.showFullPlayer = true
            })
            {
                HStack {
                    if let image = playerViewModel.currentEpisodeImage {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 45, height: 45)
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(episode.episodeTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(episode.podcastTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        playerViewModel.togglePlayPause()
                    }) {
                        Image(systemName: playerViewModel.playButtonIcon)
                            .padding()
                            .imageScale(.large)
                            .fontWeight(.heavy)
                    }
                    
                    Button(action: {
                        // TODO: Integrate settings
                        playerViewModel.skipForward(by: Int64(30))
                    })
                    {
                        Image(systemName: "\(30).arrow.trianglehead.clockwise")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .frame(height: 60)
                .background(Color(ThemeManager().selectedTheme.secondoryColor).opacity(0.9))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 90)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
        }
    }
}


//struct MiniPlayer_Previews: PreviewProvider {
//    static var previews: some View {
//        MiniPlayerView<MockPlayerViewModel>()
//            .environmentObject(MockPlayerViewModel())
//            .foregroundStyle(Color(ThemeManager().selectedTheme.primaryColor))
//    }
//}
