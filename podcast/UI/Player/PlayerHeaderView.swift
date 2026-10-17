//
//  PlayerHeaderView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/18/26.
//

import Foundation
import SwiftUI

struct PlayerHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(PlayerViewModel.self) var viewModel
    
    @State var showEpisodeNotes: Bool = false
    
    var body: some View {
        Spacer()
        Text(viewModel.currentEpisode?.episodeTitle ?? "No episode selected").lineLimit(1)
            .font(.title3)
            .fontWeight(.regular)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.top, 15)
        
        Text(viewModel.currentEpisode?.podcastTitle ?? "Podcast")
            .font(.callout)
            .foregroundStyle(Color(themeManager.selectedTheme.primaryColor)).opacity(0.7)
        Spacer()
    }
}
