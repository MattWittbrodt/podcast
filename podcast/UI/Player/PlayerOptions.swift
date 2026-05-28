//
//  PlayerOptions.swift
//  podcast
//
//  Created by Matt Wittbrodt on 12/27/25.
//

import SwiftUI

struct PlayerOptionsView: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showDescription: Bool
    
    init(showDescription: Binding<Bool>) {
        _showDescription = showDescription
    }
    
    var body: some View {
        HStack {
            Spacer()
            PlayerMenu()
                .environmentObject(playbackManager)
                .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            VStack {
                if let deviceName = playbackManager.currentAudioDeviceName {
                    Text(deviceName)
                        .fontWeight(.medium)
                        .font(.footnote)
                    AirPlayButton(activeTint: UIColor(Color(themeManager.selectedTheme.primaryColor)))
                        .frame(height: 8)
                        .tint(Color(themeManager.selectedTheme.primaryColor))
                } else {
                    AirPlayButton(activeTint: UIColor(Color(themeManager.selectedTheme.primaryColor)))
                        .frame(height: 50)
                        .tint(Color(themeManager.selectedTheme.primaryColor))
                }
            }
            Button {
                withAnimation(.linear(duration: 0.1)) {
                    showDescription.toggle()
                }
            } label: {Image(systemName: "info.circle")}
            Spacer()
        }
        .padding([.leading, .trailing], 30)
    }
}
