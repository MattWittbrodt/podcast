//
//  StringUtils.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/13/25.
//

import Foundation

extension String {
    var upgradeToHTTPS: String? {
        guard var components = URLComponents(string: self) else { return nil }
        
        // Force HTTPS if scheme is HTTP
        if components.scheme?.caseInsensitiveCompare("http") == .orderedSame {
            components.scheme = "https"
        }
        
        return components.url?.absoluteString
    }
}
