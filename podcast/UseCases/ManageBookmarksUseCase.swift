//
//  ManageBookmarksUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/12/26.
//

import Foundation

struct ManageBookmarksUseCase {
    let bookmarkRepository: BookmarkRepositoryProtocol
    
    func add(at time: TimeInterval, for episode: EpisodeRecord) throws {
        try bookmarkRepository.addBookmarkToEpisode(
            episode: episode,
            startTime: time,
        )
    }
    
    func fetchAll() async -> [BookmarkRecord] {
        do {
            return try await bookmarkRepository.fetchAll()
        } catch {
            print("bad chapter search")
            return []
        }
    }
    
    func updateLabel(_ bookmark: BookmarkRecord, label: String) async throws {
        try await bookmarkRepository.updateLabel(bookmark.objectId, label: label)
    }
    
//    func delete(_ bookmark: Bookmark) async throws {
//        try await bookmarkRepository.delete(bookmark.objectId)
//    }
//

}
