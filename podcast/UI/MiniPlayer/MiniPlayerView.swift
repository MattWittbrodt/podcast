//
//  MiniPlayerView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/20/25.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) var playbackManager
    @Environment(PlayerViewModel.self) var playerViewModel
    //@EnvironmentObject var settingsManager: SettingsManager
    @Binding var showFullPlayer: Bool
        
    init(showFullPlayer: Binding<Bool>) {
        self._showFullPlayer = showFullPlayer
    }
    
    var body: some View {
        if let episode = playerViewModel.currentEpisode {
            Button(action: {
                self.showFullPlayer = true
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
                        playbackManager.playPause()
                    }) {
                        Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                            .padding()
                            .imageScale(.large)
                            .fontWeight(.heavy)
                    }
                    
                    Button(action: {
                        // Integrate settings
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
