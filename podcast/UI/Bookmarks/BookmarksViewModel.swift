//
//  BookmarksViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 8/2/25.
//

import Foundation
import CoreData

@Observable class BookmarksViewModel {
    private let manageBookmarksUseCase: ManageBookmarksUseCase
    private let bookmarkPlaybackManager: BookmarkPlaybackManager
    var bookmarks: [BookmarkRecord] = []
    
    init(
        manageBookmarksUseCase: ManageBookmarksUseCase,
        bookmarkPlaybackManager: BookmarkPlaybackManager
    ) {
        self.manageBookmarksUseCase = manageBookmarksUseCase
        self.bookmarkPlaybackManager = bookmarkPlaybackManager
    }
    
    func fetchAll() async {
        bookmarks = await manageBookmarksUseCase.fetchAll()
    }
    
    func add(at startTime: TimeInterval, for episode: EpisodeRecord) {
        do {
            try manageBookmarksUseCase.add(at: startTime, for: episode)
        } catch {
            print("failed to save bookmark")
        }
    }
    
    func play(_ bookmark: BookmarkRecord) {
        bookmarkPlaybackManager.play(bookmark)
    }
    
    func updateLabel(_ bookmark: BookmarkRecord, label: String) async {
        try? await manageBookmarksUseCase.updateLabel(bookmark, label: label)
        await fetchAll()  // reload to reflect change
    }
}
