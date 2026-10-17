//
//  CreateBookmarkClipUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/12/26.
//

import Foundation
import AVKit

protocol CreateBookmarkClipUseCaseProtocol {
    func execute(episode: EpisodeRecord, bookmark: BookmarkRecord, duration: TimeInterval) async throws
}

struct CreateBookmarkClipUseCase: CreateBookmarkClipUseCaseProtocol {
    let bookmarkRepository: BookmarkRepositoryProtocol
    let filePathService: FilePathService
    
    func execute(
        episode: EpisodeRecord,
        bookmark: BookmarkRecord,
        duration: TimeInterval = 180
    ) async throws {
        guard filePathService.downloadFileExists(for: episode.savedFileName()) != nil else {
            throw BookmarkError.episodeNotDownloaded
        }
        
        let asset = AVURLAsset(url: episode.audioUrl)
        let outputURL = filePathService.url(for: bookmark)
        
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw BookmarkError.exportFailed
        }
        
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: bookmark.startTime, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
        
        try await exporter.export(to: outputURL, as: .m4a)
        print("!!! Created clip: \(outputURL)")
    }
}
