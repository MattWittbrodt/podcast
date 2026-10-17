//
//  PlayerOptions.swift
//  podcast
//
//  Created by Matt Wittbrodt on 12/27/25.
//
import SwiftUI
import AVKit

struct PlayerOptionsView: View {
    @Environment(PlayerViewModel.self) var viewModel
    @Environment(BookmarksViewModel.self) var bookmarksViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // AirPlay centered absolutely
            VStack {
                if let deviceName = viewModel.audioDeviceName {
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
            
            // Menu left, bookmark right
            HStack {
                PlayerMenu()
                    .environment(viewModel)
                    .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
                    .frame(width: 75) // need this so they are equidistant from the airplay
                
                Spacer()
                
                Button(action: {
                    guard let episode = viewModel.currentEpisode else { return }
                    bookmarksViewModel.add(at: viewModel.currentTime, for: episode)
                }) {
                    Image(systemName: "bookmark")
                        .resizable()
                        .frame(width: 16, height: 25)
                }
                .frame(width: 75)
                .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            }
        }
    }
}

struct PlayerMenu: View {
    @Environment(PlayerViewModel.self) var viewModel
    let rates: [Float] = [0.75,1.0,1.25,1.5,1.75,2.0]
    
    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button {
                    Task { viewModel.updateRate(rate) }
                } label: {
                    LabeledContent {
                        if rate == viewModel.playbackRate {
                            Image(systemName: "checkmark")
                        }
                    } label: {
                        Text("\(formatFloat(rate))x")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(formatFloat(viewModel.playbackRate))x")
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct AirPlayButton: UIViewRepresentable {
    var activeTint: UIColor
    
    init(activeTint: UIColor = .blue) {
        self.activeTint = activeTint
    }
    
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView(frame: .zero)
        routePickerView.prioritizesVideoDevices = false
        routePickerView.activeTintColor = activeTint
        
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

#Preview {
    PlayerOptionsView()
        .environmentObject(ThemeManager())
        .environment(PlayerViewModel.preview)
        .environment(BookmarksViewModel.preview)
}
