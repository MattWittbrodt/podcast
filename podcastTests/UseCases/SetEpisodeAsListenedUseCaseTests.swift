//
//  SetEpisodeAsListenedUseCaseTests.swift
//  podcastTests
//
//  Created by Matt Wittbrodt on 7/22/26.
//

import Foundation
import Testing
import CoreData
@testable import podcast

//struct SetEpisodeAsListenedUseCaseTests {
//    
//    // MARK: - forPlayback
//    @Test func execute_returnsSome() async {
//        // Given
//        let mockRepo = MockEpisodeRepository()
//        mockRepo.stubbedEpisode = nil
//        
//        let mockBookmark = MockBookmarksRepository()
//                
//        let sut = SetEpisodeAsListenedUseCase(
//            downloadManager: DownloadManager(),
//            episodeRepository: mockRepo,
//            bookmarkRepository: mockBookmark,
//            createBookmarkClipUseCase: MockCreateBookmarkClipUseCase()
//        )
//        
//        // When
//        let result = await sut.execute(<#T##episode: EpisodeRecord##EpisodeRecord#>)(episodeID: mockRepo.placeholderID)
//        
//        // Then
//        #expect(result == nil)
//    }
//    
//    
//}

@Suite(.serialized)
struct SetEpisodeAsListenedUseCaseTests {

    @Test("clips bookmarks and marks episode as listened")
    func execute_clipsBookmarksAndMarksEpisodeAsListened() async throws {
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        let podcast = Podcast(context: context)
        podcast.feedUrl = "samplefeed"
        let episode = Episode(context: context)
        episode.publishedDate = Date()
    
        episode.podcast = podcast
        
        let bookmark = Bookmark(context: context)
        bookmark.savedDate = Date()
        bookmark.bookmarkEpisode = episode
        
        do {
            try context.save()
        } catch let error as NSError {
            if let detailed = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for e in detailed {
                    print(e.code, e.userInfo[NSValidationKeyErrorKey] ?? "?", e.userInfo[NSValidationObjectErrorKey] ?? "?")
                }
            }
            throw error
        }
        
        let episodeRecord = EpisodeRecord.makeSampleForTest(
            title: "Test title",
            publishedDate: Date.distantPast,
            audioUrl: nil,
            context: context)
        let bookmarkRecord = BookmarkRecord.makeSampleForTest(
            bookmark: bookmark,
            episode: episode
        )

        let bookmarkRepository = MockBookmarkRepository(stubbedBookmarks: [bookmarkRecord])

        let episodeRepository = MockEpisodeRepository()
//        let createBookmarkClipUseCase = MockCreateBookmarkClipUseCase()
        let downloadManager = DownloadManager()
        let createBookmarkClipUseCase = CreateBookmarkClipUseCase(
            bookmarkRepository: bookmarkRepository,
            filePathService: FilePathService()
        )

        let sut = SetEpisodeAsListenedUseCase(
            downloadManager: downloadManager,
            episodeRepository: episodeRepository,
            bookmarkRepository: bookmarkRepository,
            createBookmarkClipUseCase: createBookmarkClipUseCase
        )

        // Act
        _ = try await sut.execute(episodeRecord)

        // Assert (i) clip was created for the bookmark
        //#expect(createBookmarkClipUseCase.executeWasCalledTimes == 1)
        

    }
}
