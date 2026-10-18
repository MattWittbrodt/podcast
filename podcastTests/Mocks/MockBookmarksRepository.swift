//
//  MockBookmarksRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 7/22/26.
//

import Foundation
import CoreData
@testable import podcast

final class MockBookmarkRepository: BookmarkRepositoryProtocol {
    let stubbedBookmarks: [BookmarkRecord]
    
    init(stubbedBookmarks: [BookmarkRecord] = []) {
        self.stubbedBookmarks = stubbedBookmarks
    }
    
    func addBookmarkToEpisode(episode: EpisodeRecord, startTime: TimeInterval) throws {}
    func fetchAll() async throws -> [BookmarkRecord] { [] }
    func fetchAll(for episodeId: NSManagedObjectID) async throws -> [BookmarkRecord] { stubbedBookmarks }
    func updateLabel(_ id: NSManagedObjectID, label: String) async throws {}
}
