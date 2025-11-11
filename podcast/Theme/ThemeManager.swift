//
//  ThemeManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/24/25.
//

import SwiftUI
/**
 Theme Manager
 */
class ThemeManager: ObservableObject {
    @Published var selectedTheme: ThemeProtocol = Main()
    
    func setTheme(_ theme: ThemeProtocol) {
        selectedTheme = theme
    }
}
