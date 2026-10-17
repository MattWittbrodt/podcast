//
//  FinishEpisodeUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/14/26.
//

import Foundation
import CoreData

struct SetEpisodeAsListenedUseCase {
    let downloadManager: DownloadManager
    let episodeRepository: EpisodeRepositoryProtocol
    let bookmarkRepository: BookmarkRepositoryProtocol
    let createBookmarkClipUseCase: CreateBookmarkClipUseCaseProtocol
    
    static let clipDuration: TimeInterval = 180

    func execute(_ episode: EpisodeRecord) async throws -> EpisodeRecord? {
        // First, clip bookmarks before removing download
        do {
            let bookmarks = try await bookmarkRepository.fetchAll(for: episode.objectId)
            for bookmark in bookmarks {
                try await createBookmarkClipUseCase.execute(
                    episode: episode,
                    bookmark: bookmark,
                    duration: Self.clipDuration
                )
            }
        } catch {
            print("bookmarks clipping failed: \(error)")
            if let nsError = error as NSError? {
                    print("domain: \(nsError.domain) code: \(nsError.code)")
                    print("userInfo: \(nsError.userInfo)")
                    if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("underlying: \(underlying.domain) \(underlying.code)")
                    }
                }
        }
        
        episodeRepository.markEpisodeAsListened(episode.objectId)
        downloadManager.removeDownload(for: episode)

        // Only start playing next episode if the one marked as played is currently playing
        return try? await episodeRepository.fetchNextEpisode(after: episode.objectId)
    }
}
