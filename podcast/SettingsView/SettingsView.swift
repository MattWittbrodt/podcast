//
//  Settings.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/15/25.
//

import SwiftUI
import CoreData

enum SettingsAction: Identifiable {
    case deleteDownloads
    case clearLibrary
    
    var id: String {
        switch self {
        case .deleteDownloads: return "delete"
        case .clearLibrary: return "library"
        }
    }
    
    var title: String {
        switch self {
        case .deleteDownloads: return "Delete Downloads"
        case .clearLibrary: return "Reset Library"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var activeAction: SettingsAction?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        List {
            Section("Playback Settings") {}
            Section("Data Management") {
                Stepper(value: $settingsManager.numDownloads, in: 0...99) {
                    Text("Keep Last \(settingsManager.numDownloads) Downloads Per Podcast")
                }
                Button("Remove Downloads") { activeAction = .deleteDownloads }
                Button("Clear Library") { activeAction = .clearLibrary }
            }
        }
        // This sheet appears whenever activeAction is not nil
        .sheet(item: $activeAction) { action in
            ModalView(action: action) {
                performAction(action)
            }
        }
        // Generic error alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .tint(themeManager.selectedTheme.primaryColor)
    }
    
    func performAction(_ action: SettingsAction) {
        Task {
            do {
                switch action {
                case .deleteDownloads:
                    try await settingsManager.deleteDownloads()
                case .clearLibrary:
                    try await settingsManager.deleteDownloads()
                }
                activeAction = nil
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

#Preview {
    let dataManager = DataManager.preview
    let downloadManager = DownloadManager(dataManager: dataManager)
    let settingsManager = SettingsManager(downloadManager: downloadManager, dataManager: dataManager)
    
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(settingsManager)
}
