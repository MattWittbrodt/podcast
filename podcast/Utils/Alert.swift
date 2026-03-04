//
//  Alert.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/2/26.
//

import Foundation

enum AlertType: Identifiable {
    case cellularDownload

    var id: String {
        switch self {
        case .cellularDownload: return "Cellular downloads are not currently enabled"
        }
    }
}
