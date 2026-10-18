//
//  LoadEpisodeUseCaseTests.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/20/26.
//

import Foundation
import Testing
@testable import podcast

@Suite(.serialized)
struct LoadEpisodeUseCaseTests {
    
    // MARK: - forPlayback
    @Test func forPlayback_returnsNil_whenEpisodeNotFound() async {
        // Given
        let mockRepo = MockEpisodeRepository()
        mockRepo.stubbedEpisode = nil
        let sut = LoadEpisodeUseCase(
            episodeRepo: mockRepo,
            playbackUseCase: MockPlaybackUseCase()
        )
        
        // When
        let result = await sut.forPlayback(episodeID: mockRepo.placeholderID)
        
        // Then
        #expect(result == nil)
    }
    
    @Test func forPlayback_startsPlayback_whenEpisodeFound() async {
        // Given
        let mockRepo = MockEpisodeRepository()
        let mockPlayback = MockPlaybackUseCase()
        mockRepo.stubbedEpisode = .preview
        let sut = LoadEpisodeUseCase(
            episodeRepo: mockRepo,
            playbackUseCase: mockPlayback
        )
        
        // When
        let _ = await sut.forPlayback(episodeID: mockRepo.placeholderID)
        
        // Then
        #expect(mockPlayback.playWasCalled == true)
    }
    
    @Test func forPlayback_returnsEpisodeAndArtwork_whenFound() async {
        // Given
        let mockRepo = MockEpisodeRepository()
        mockRepo.stubbedEpisode = .preview
        mockRepo.stubbedImageData = Data()
        let sut = LoadEpisodeUseCase(
            episodeRepo: mockRepo,
            playbackUseCase: MockPlaybackUseCase()
        )
        
        // When
        let result = await sut.forPlayback(episodeID: mockRepo.placeholderID)
        
        // Then
        #expect(result?.episode != nil)
        #expect(result?.artwork != nil)
    }
    
    // MARK: - forUnlistened
    @Test func forUnlistened_returnsSortedEpisodes() async throws {
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        // Given
        let mockRepo = MockEpisodeRepository()
        
        let date1 = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let date2 = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 14))!
        let date3 = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 21))!
        mockRepo.stubbedUnlistened = [
            EpisodeRecord.makeSampleForTest(title: "old", publishedDate: date1, audioUrl: nil, context: context),
            EpisodeRecord.makeSampleForTest(title: "old2", publishedDate: date2, audioUrl: nil, context: context),
            EpisodeRecord.makeSampleForTest(title: "selected", publishedDate: date3, audioUrl: nil, context: context)
        ]

        let sut = LoadEpisodeUseCase(
            episodeRepo: mockRepo,
            playbackUseCase: MockPlaybackUseCase()
        )
        
        // When
        let results = try await sut.forUnlistened()
        
        // Then
        #expect(results.count == 3)
        #expect(results.first!.episodeTitle == "selected")
    }
}


