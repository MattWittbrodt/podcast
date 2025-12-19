//
//  PlayerEpisodeDescriptionView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/5/25.
//

import SwiftUI

struct PlayerEpisodeDescriptionView: View {
    let html: AttributedString
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Text(html)
                    .padding(40)
                    .frame(width: max(0, geometry.size.width - 20), alignment: .leading)
            }
        }
    }
}


