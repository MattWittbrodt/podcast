//
//  PlayerEpisodeDescriptionView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/5/25.
//

import SwiftUI

struct PlayerEpisodeDescriptionView: View {
    let html: String
    let theme: ThemeManager
    @State private var attributedString = AttributedString()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Text(attributedString)
                    .padding(40)
                    .frame(width: max(0, geometry.size.width - 20), alignment: .leading)
                    .onAppear {
                        attributedString = parseHTML(html: html)
                    }
            }
        }
    }
    
    private func parseHTML(html: String) -> AttributedString {
        do {
            guard let data = html.data(using: .utf8) else {
                return AttributedString(html)
            }
            
            let nsAttributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            
            var result = AttributedString(nsAttributedString)
            
            // Fix for iOS 18+ font issues
            result.font = .body
            result.foregroundColor = theme.selectedTheme.primaryColor
                        
            return result
        } catch {
            return AttributedString("Error parsing HTML: \(error.localizedDescription)")
        }
    }
}


