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
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var activeAction: SettingsAction?
    @State private var errorMessage: String?
    @State private var showError = false
    
    @StateObject private var viewModel: SettingsViewModel
    
    init(useCase: ManageSettingsUseCase) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            useCase: useCase,
        ))
    }
    
    var body: some View {
        List {
            Section("Playback Settings") {
                VStack {
                    LabeledContent("Skip Forward (s)") {}
                        .fontWeight(.light)
                    Picker("Skip forward", selection: $viewModel.forwardSkip) {
                        ForEach(viewModel.skipOptions, id: \.self) { time in
                            Text("\(time)")
                                .tag(Int16(time))
                        }
                    }.pickerStyle(.segmented)
                }
                VStack{
                    LabeledContent("Skip Backward (s)") {}
                        .fontWeight(.light)
                    Picker("Skip forward", selection: $viewModel.backwardSkip) {
                        ForEach(viewModel.skipOptions, id: \.self) { time in
                            Text("\(time)")
                                .tag(Int16(time))
                        }
                    }.pickerStyle(.segmented)
                }
            }
            .listRowBackground(themeManager.selectedTheme.primaryColor.opacity(0.1))
            Section("Data Management") {
                Toggle("Allow Downloads on Cellular", isOn: $viewModel.allowCellularDownloads)
                Stepper(value: $viewModel.numDownloads, in: 0...99) {
                    Text("Keep Last \(viewModel.numDownloads) Downloads Per Podcast").foregroundStyle(themeManager.selectedTheme.primaryColor)
                }
                Button("Remove Downloads") { activeAction = .deleteDownloads }
                Button("Clear Library") { activeAction = .clearLibrary }
            }
            .listRowBackground(themeManager.selectedTheme.primaryColor.opacity(0.1))
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
        .scrollContentBackground(.hidden)
        .tint(themeManager.selectedTheme.primaryColor)
        .background(themeManager.selectedTheme.secondoryColor)
    }
    
    func performAction(_ action: SettingsAction) {
        Task {
            do {
                switch action {
                case .deleteDownloads:
                    try await downloadManager.deleteMp3Files()
                case .clearLibrary:
                    try await downloadManager.deleteMp3Files()
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

//#Preview {
//    let dataManager = DataManager.preview
//    let settingsManager = SettingsManager(dataManager: dataManager)
//    let downloadManager = DownloadManager()
//    //downloadManager.allowCellularDownloads = { settingsManager.allowCellularDownloads }
//    
//    SettingsView()
//        .environmentObject(ThemeManager())
//        .environmentObject(settingsManager)
//}
