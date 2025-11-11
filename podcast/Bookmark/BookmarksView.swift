//
//  BookmarksView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 8/2/25.
//

import SwiftUI

struct BookmarksView<ViewModel: PlayerViewModelProtocol>: View {
    @State private var viewModel = BookmarksViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var playerManager: ViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    var body: some View {
        NavigationStack {
            content
                .background(Color(themeManager.selectedTheme.secondoryColor))
                .onAppear {
                    Task {
                        viewModel.setup(context: persistenceManager.viewContext)
                        await viewModel.loadBookmarks()
                    }
                }
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                header
                bookmarkList(in: geometry)
            }
            .padding(.horizontal)
        }
    }
    
    private var header: some View {
        HStack {
            Text("Bookmarks")
                .font(.title)
                .fontWeight(.medium)
            Spacer()
        }
    }
    
    private func bookmarkList(in geometry: GeometryProxy) -> some View {
        List {
            bookmarkListContent()
        }
        .listStyle(.plain)
        .background(themeManager.selectedTheme.secondoryColor)
        .scrollContentBackground(.hidden)
    }
    
    private func bookmarkListContent() -> some View {
        ForEach(viewModel.bookmarks) { bookmark in
            VStack {
                Text(bookmark.bookmarkEpisode?.podcastTitle ?? "")
                Text(bookmark.bookmarkEpisode?.title ?? "")
                Text("\(bookmark.startTime)")
            }
        }
    }
}

//#Preview {
//    BookmarksView()
//}
