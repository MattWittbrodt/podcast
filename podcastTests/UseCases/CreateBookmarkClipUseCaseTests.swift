//
//  CreateBookmarkClipUseCaseTests.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 8/8/26.
//

import Testing
import Foundation
@testable import podcast

final class TestBundleLocator {}

@Test("clips the requested duration from downloaded audio")
func execute_writesClip() async throws {
    // 1. locate the fixture in the test bundle
    let fixture = try #require(
        Bundle(for: TestBundleLocator.self).url(forResource: "sample", withExtension: "m4a")
    )
    
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
    
    let episodeRecord = EpisodeRecord.makeSampleForTest(
        title: "Test title",
        publishedDate: Date.distantPast,
        audioUrl: fixture,
        context: context)
    let bookmarkRecord = BookmarkRecord.makeSampleForTest(
        bookmark: bookmark,
        episode: episode
    )

    // 2. copy it where the service expects to find it
    let tempDir = URL.temporaryDirectory.appending(path: UUID().uuidString)
    let filePathService = FilePathService(downloadsDirectory: tempDir)
    let destination = filePathService.url(for: episodeRecord)
    
    try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try FileManager.default.copyItem(at: fixture, to: destination)
    defer { try? FileManager.default.removeItem(at: destination) }
    
    print("copied to:  \(destination.path)")
    print("looking for: \(episodeRecord.savedFileName())")
    print("resolves to: \(String(describing: filePathService.downloadFileExists(for: episodeRecord.savedFileName())))")
    print("dir contents: \(try FileManager.default.contentsOfDirectory(atPath: destination.deletingLastPathComponent().path))")

    // 3. now the guard passes
    let bookmarkRepository = MockBookmarkRepository(stubbedBookmarks: [bookmarkRecord])
    let sut = CreateBookmarkClipUseCase(
        bookmarkRepository: bookmarkRepository,
        filePathService: filePathService
    )
    try await sut.execute(episode: episodeRecord, bookmark: bookmarkRecord, duration: 10)
    
    // Run cleanup to remove any created file
    defer {
        if let clip = filePathService.downloadFileExists(for: bookmarkRecord.savedFileName()) {
            try? FileManager.default.removeItem(at: clip)
        }
    }

    // 4. assert
    #expect(FileManager.default.fileExists(atPath: filePathService.url(for: bookmarkRecord).path))
    #expect(filePathService.downloadFileExists(for: bookmarkRecord.savedFileName()) != nil)
    
}
