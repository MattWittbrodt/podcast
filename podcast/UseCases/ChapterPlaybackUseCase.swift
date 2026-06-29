//
//  ChapterPlaybackUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/22/26.
//

import Foundation
import UIKit

final class ChapterPlaybackUseCase {
    private let imageService: ImageService
    private var lastChapterStartTime: Int16?

    struct ChapterTransition {
        let chapter: ChapterRecord
        let artwork: UIImage?
    }

    init(imageService: ImageService = ImageService()) {
        self.imageService = imageService
    }

    // Called by the ViewModel on every time update
    func checkTransition(
        at time: TimeInterval,
        in episode: EpisodeRecord
    ) async -> ChapterTransition? {
        guard let chapter = episode.chapter(at: time) else { return nil }

        // No transition if we're still in the same chapter
        guard chapter.startTime != lastChapterStartTime else { return nil }
        lastChapterStartTime = chapter.startTime

        // Crossed a boundary — load new artwork if this chapter has its own
        let artwork: UIImage?
        if let data = chapter.imageData {
            artwork = UIImage(data: data)
        } else if let imageUrl = chapter.imageUrl, !imageUrl.isEmpty {
            if let data = await imageService.getImageData(from: imageUrl) {
                artwork = UIImage(data: data)
            } else {
                artwork = nil
            }
        } else {
            artwork = nil
        }
        
        return ChapterTransition(chapter: chapter, artwork: artwork)
    }

    func reset() {
        lastChapterStartTime = nil
    }
}
