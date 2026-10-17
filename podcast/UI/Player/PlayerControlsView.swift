//
//  PlayerControlsView.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 7/18/26.
//

import SwiftUI
import Foundation

struct PlayerControlsView: View {
    @Environment(PlayerViewModel.self) var viewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    
    var body: some View {
        @Bindable var viewModel = viewModel
        VStack {
            Slider(
                value: $viewModel.currentTime,
                in: 0...viewModel.duration,
                onEditingChanged: { isEditing in
                    viewModel.setIsSeeking(isEditing)
                    if !isEditing {
                        viewModel.finishedScrubbing()
                    }
                }
            )
            .tint(themeManager.selectedTheme.primaryColor)
            
            HStack {
                Text("\(viewModel.currentTimeString)")
                    .fontWeight(.semibold)
                Spacer()
                Text("- \(formattedTime(time: Double(viewModel.duration)-viewModel.currentTime))")
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 20)
            
            HStack {
                Button(action: { viewModel.skipBackward() }) {
                    Image(systemName: "gobackward.\(viewModel.backwardSkip)")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
                Spacer()
                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.playButtonIcon)
                        .resizable()
                        .frame(width: 35, height: 45 )
                }
                Spacer()
                Button(action: { viewModel.skipForward() }) {
                    Image(systemName: "goforward.\(viewModel.forwardSkip)")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
            }
        }
    }
}

#Preview {
    PlayerControlsView()
        .environmentObject(ThemeManager())
        .environment(PlayerViewModel.preview)
}
