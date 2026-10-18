//
//  PlayerNotesAndImage.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/18/26.
//

import Foundation
import SwiftUI

struct PlayerNotesAndImage: View {
    @Environment(PlayerViewModel.self) var viewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showDescription: Bool
    
    init(showDescription: Binding<Bool>) {
        _showDescription = showDescription
    }
    
    var body: some View {
        VStack {
            EpisodeImageView(showDescriptions: $showDescription)
                .environment(viewModel)
            if showDescription {
                PlayerEpisodeDescriptionView(
                    html: viewModel.currentEpisodeDescription ?? "Bad"
                )
                .environmentObject(themeManager)
            }
        }
    }
}

struct EpisodeImageView: View {
    @Environment(PlayerViewModel.self) var viewModel
    @Binding var showDescriptions: Bool
    
    init(showDescriptions: Binding<Bool>) {
        _showDescriptions = showDescriptions
    }
    
    var body: some View {
        if let uIImg = viewModel.currentEpisodeImage {
            if !showDescriptions {
                Image(uiImage: uIImg)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(25)
            } else {
                Image(uiImage: uIImg)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(5)
                    .animation(.linear)
            }
        } else {
            EmptyView()
        }
    }
}
