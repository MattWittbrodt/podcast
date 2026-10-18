//
//  MockUseCases.swift
//  podcastTests
//
//  Created by Matt Wittbrodt on 7/20/26.
//

import Foundation
import CoreData
@testable import podcast

final class MockPlaybackUseCase: PlaybackUseCaseProtocol {
    var playWasCalled = false
    var lastPlayedEpisode: EpisodeRecord?
    var lastPlayedBookmark: BookmarkRecord?
    
    func play(episode: EpisodeRecord) {
        playWasCalled = true
        lastPlayedEpisode = episode
    }
    
    func play(bookmark: BookmarkRecord) {
        playWasCalled = true
        lastPlayedBookmark = bookmark
    }
    
    func updateRate(_ rate: Float, for episode: EpisodeRecord) { return }
    func updateLastListened(for episode: EpisodeRecord, at time: TimeInterval) async {
        return
    }
}

final class MockCreateBookmarkClipUseCase: CreateBookmarkClipUseCaseProtocol {
    var executeWasCalledTimes = 0
    var episodePassedIn: [NSManagedObjectID] = []
    
    func execute(
        episode: EpisodeRecord,
        bookmark: BookmarkRecord,
        duration: TimeInterval) async throws {
        executeWasCalledTimes += 1
    }
}
