//
//  MiniPlayerView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/20/25.
//

import SwiftUI

struct MiniPlayerView<ViewModel: PlayerViewModelProtocol>: View {
    @EnvironmentObject var playerManager: ViewModel
    
    var body: some View {
        if let episode = playerManager.currentEpisode {
            Button(action: {
                playerManager.showFullPlayer = true
            })
            {
                HStack {
                    if let image = playerManager.episodeImageData {
                        if let idata = UIImage(data: image) {
                            Image(uiImage: idata)
                                .resizable()
                                .frame(width: 45, height: 45)
                                .cornerRadius(4)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(episode.title ?? "Podcast title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(episode.podcast?.title ?? "Now playing")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        playerManager.playPause()
                    }) {
                        //let _ = print("Mini: \(playerManager.playerState)")
                        Image(systemName: playerManager.playerState == PlayerState.playing ? "pause.fill" : "play.fill")
                            .padding()
                            .imageScale(.large)
                            .fontWeight(.heavy)
                    }
                    
                    Button(action: {
                        playerManager.skipForward(seconds: 30)
                    })
                    {
                        Image(systemName: "30.arrow.trianglehead.clockwise")
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
