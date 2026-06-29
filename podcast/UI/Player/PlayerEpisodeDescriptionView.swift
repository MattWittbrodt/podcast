//
//  PlayerEpisodeDescriptionView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/5/25.
//

import SwiftUI

extension AttributedString {
    func withColor(_ color: Color) -> AttributedString {
        var copy = self
        copy[copy.startIndex..<copy.endIndex].foregroundColor = color
        return copy
    }
}

struct PlayerEpisodeDescriptionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let html: AttributedString
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Text(html.withColor(themeManager.selectedTheme.primaryColor))
                    .padding(40)
                    .frame(width: max(0, geometry.size.width - 20), alignment: .leading)
            }
        }
    }
}


