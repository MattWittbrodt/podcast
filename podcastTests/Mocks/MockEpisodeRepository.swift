//
//  MockEpisodeRepository.swift
//  podcastTests
//
//  Created by Matt Wittbrodt on 7/20/26.
//

import Foundation
import CoreData
@testable import podcast

final class MockEpisodeRepository: EpisodeRepositoryProtocol, @unchecked Sendable {
    var stubbedEpisode: EpisodeRecord?
        
    var stubbedImageData: Data?
    var stubbedUnlistened: [EpisodeRecord] = []
    var updateLastListenedCallCount = 0
    
    // Placeholder ID for tests — avoids needing real Core Data
    let placeholderID: NSManagedObjectID = {
        let pc = PersistenceController(inMemory: true)
        let ep = Episode(context: pc.container.viewContext)
        pc.container.viewContext.processPendingChanges()
        return ep.objectID
    }()
    
    func fetchForPlayback(for id: NSManagedObjectID) async -> EpisodeRecord? { stubbedEpisode }
    
    func getImageData(for id: NSManagedObjectID) async -> Data? {
        stubbedImageData
    }
    
    func fetchUnlistened() async throws -> [EpisodeRecord] {
        stubbedUnlistened
    }
    
    func updateLastListened(for id: NSManagedObjectID, time: Double) async {
        updateLastListenedCallCount += 1
    }
    
    func fetchAllforPodcast(for podcastId: NSManagedObjectID) async -> [EpisodeRecord] {
        return []
    }
    
    func getRecentEpisodesForEachPodcast(limit: Int) async -> [EpisodeRecord] { return [] }
    func getEpisode(for id: NSManagedObjectID) -> Episode? { return nil }
    func getUnlistenedEpisodesWithChapters() throws -> [Episode] { return [] }
    func updateChapters(for episodeID: NSManagedObjectID, with chapterInfos: [ChapterInfo]) async throws {}
    func markAsManuallyDownloaded(_ id: NSManagedObjectID) async {}
    func markEpisodeAsListened(_ id: NSManagedObjectID) {}
    func markEpisodeAsUnlistened(_ episode: Episode) {}
    func updateDurationFromFile(for episodeId: NSManagedObjectID, length: Int16) async {}
    func importEpisodes(from channel: RSSChannel, for podcastID: NSManagedObjectID) async throws -> EpisodeRecord? { return nil }
    func fetchNextEpisode(after episodeID: NSManagedObjectID) async throws -> EpisodeRecord? { return nil }
    func getChaptersForId(for id: NSManagedObjectID) async -> [ChapterRecord] { return [] }
}
