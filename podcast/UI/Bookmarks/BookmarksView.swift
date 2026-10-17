//
//  BookmarksView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/12/26.
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(BookmarksViewModel.self) private var viewModel
    
    @State private var showLabelEditor = false
    @State private var editingBookmark: BookmarkRecord?
    @State private var editingLabel = ""
    
    var body: some View {
        List(viewModel.bookmarks) { (bookmark: BookmarkRecord) in
            Button {
                Task { viewModel.play(bookmark) }
            } label: {
                VStack(alignment: .leading) {
                    if let customLabel = bookmark.customLabel {
                        Text(customLabel)
                            .font(.headline)
                        Text("\(bookmark.episodeTitle) - \(bookmark.podcastTitle)")
                            .italic()
                    } else {
                        Text("\(bookmark.episodeTitle)")
                            .font(.headline)
                        Text(bookmark.podcastTitle)
                            .italic()
                    }
                    Text("Saved on: \(bookmark.savedDate.bookmarkFormatted())")
                }
            }
            .foregroundStyle(themeManager.selectedTheme.primaryColor)
            .onLongPressGesture {
                editingBookmark = bookmark
                editingLabel = bookmark.customLabel ?? ""
                showLabelEditor = true
            }
            .listRowBackground(Color(themeManager.selectedTheme.secondaryColor))
        }
        .scrollContentBackground(.hidden)
        .overlay {
            if viewModel.bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Add bookmarks while listening to episodes")
                )
            }
        }
        .task {
            guard viewModel.bookmarks.isEmpty else { return }
            await viewModel.fetchAll()
        }
        .alert("Edit Bookmark Name", isPresented: $showLabelEditor) {
            TextField("Label", text: $editingLabel)
            Button("Save") {
                guard let bookmark = editingBookmark else { return }
                Task { await viewModel.updateLabel(bookmark, label: editingLabel) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .background(Color(themeManager.selectedTheme.secondaryColor).ignoresSafeArea())
        .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
    }
}


#Preview {
    @Previewable @State var vm = BookmarksViewModel.preview
    BookmarksView()
        .environment(PlayerViewModel.preview)
        .environment(vm)
        .environmentObject(ThemeManager())
}
