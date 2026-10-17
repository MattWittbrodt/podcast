//
//  BookmarkRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 7/12/26.
//

import CoreData

protocol BookmarkRepositoryProtocol: Sendable {
    func addBookmarkToEpisode(episode: EpisodeRecord, startTime: TimeInterval) throws
    func fetchAll() async throws -> [BookmarkRecord]
    func fetchAll(for episodeId: NSManagedObjectID) async throws -> [BookmarkRecord]
    func updateLabel(_ id: NSManagedObjectID, label: String) async throws
}

final class BookmarkRepository: BookmarkRepositoryProtocol {
    private let context: NSManagedObjectContext
    private let filePathservice: FilePathService = FilePathService()

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    private func getBookmarkAudioPath(for bookmark: Bookmark) -> (URL, Bool)? {
        // This needs to be set upon creation so should not crash
        guard let episode = bookmark.bookmarkEpisode else { return nil }
        
        print("Searching for: \(episode.savedFileName())")
        print("Searching for: \(bookmark.savedFileName())")
        
        if filePathservice.downloadFileExists(for: episode.savedFileName()) != nil {
            return (filePathservice.url(for: episode.savedFileName()), true)
        } else if filePathservice.downloadFileExists(for: bookmark.savedFileName()) != nil {
            return (filePathservice.url(for: bookmark.savedFileName()), false)
        } else {
            print("No bookmark info for: \(episode.title) - \(bookmark.startTime)")
            return nil
        }
    }
    
    func addBookmarkToEpisode(
        episode: EpisodeRecord,
        startTime: TimeInterval
    ) throws {
        let episodeCD = try self.context.existingObject(with: episode.objectId) as? Episode
        let bookmark = Bookmark(context: self.context)
        bookmark.startTime = startTime
        bookmark.savedDate = Date()
        bookmark.bookmarkEpisode = episodeCD
        
        // TODO: Handle streaming bookmarks
        
        try? self.context.save()
    }
    
    func fetchAll() async throws -> [BookmarkRecord] {
        try await context.perform {
            let request = Bookmark.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
            
            return try self.context.fetch(request).compactMap { bookmark in
                guard let episode = bookmark.bookmarkEpisode,
                      let (audioUrl, fromEpisode) = self.getBookmarkAudioPath(for: bookmark) else {
                    return nil
                }
                return BookmarkRecord(
                    objectId: bookmark.objectID,
                    savedDate: bookmark.savedDate ?? Date(),
                    customLabel: bookmark.customLabel,
                    audioFilePath: audioUrl,
                    isAudioFromEpisode: fromEpisode,
                    startTime: bookmark.startTime,
                    episodeId: bookmark.bookmarkEpisode!.objectID,
                    episodeTitle: bookmark.bookmarkEpisode?.title ?? "No title",
                    podcastTitle: bookmark.bookmarkEpisode?.podcast?.title ?? "No podcast title",
                    publishedDate: bookmark.bookmarkEpisode?.publishedDate
                )
            }
        }
    }
    
    func fetchAll(for episodeId: NSManagedObjectID) async throws -> [BookmarkRecord] {
        try await context.perform {
            guard let episode = try? self.context.existingObject(with: episodeId) as? Episode else {
                throw RepositoryError.notFound
            }
            
            let bookmarks = episode.bookmarks as? Set<Bookmark> ?? []
            
            return bookmarks
                .sorted { ($0.savedDate ?? .distantPast) > ($1.savedDate ?? .distantPast) }
                .compactMap { bookmark in
                    let (audioUrl, fromEpisode) = self.getBookmarkAudioPath(for: bookmark)!
                    
                    return BookmarkRecord(
                        objectId: bookmark.objectID,
                        savedDate: bookmark.savedDate ?? Date(),
                        customLabel: bookmark.customLabel,
                        audioFilePath: audioUrl,
                        isAudioFromEpisode: fromEpisode,
                        startTime: bookmark.startTime,
                        episodeId: episode.objectID,
                        episodeTitle: episode.title ?? "No title",
                        podcastTitle: episode.podcast?.title ?? "No podcast title",
                        publishedDate: episode.publishedDate
                    )
                }
        }
    }
    
    func updateLabel(_ id: NSManagedObjectID, label: String) async throws {
        try await context.perform {
            guard let bookmark = try? self.context.existingObject(with: id) as? Bookmark else { return }
            bookmark.customLabel = label
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
}
