//
//  PlaybackManagerDescription.swift
//  podcast
//
//  Created by Matt Wittbrodt on 12/6/25.
//

import Foundation

extension PlaybackManager {
    
    func parseHTML(html: String?) -> AttributedString? {
        guard let html = html else { return nil }
        guard let data = html.data(using: .utf8) else {
            print("HTML parsing failed")
            return AttributedString(html)
        }
        
        do {
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

            return result
        } catch {
            return AttributedString("Error parsing HTML: \(error.localizedDescription)")
        }
    }
}
