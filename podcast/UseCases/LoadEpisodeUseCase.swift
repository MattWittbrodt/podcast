//
//  LoadEpisodeUseCase.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 6/21/26.
//

import Foundation
import CoreData

struct LoadEpisodeUseCase {
    let episodeRepo: EpisodeRepository
    let playbackUseCase: PlaybackUseCase

    struct Output {
        let episode: EpisodeRecord
        let artwork: Data?
    }

    func forPlayback(episodeID: NSManagedObjectID) async -> Output? {
        // 1. Hydrate from Core Data (last listened, play count, download path, etc.)
        guard let episode = await episodeRepo.fetchForPlayback(for: episodeID) else { return nil }
        
        // 2. Load artwork + start playback IN PARALLEL — don't wait for artwork to play
        async let artwork = episodeRepo.getImageData(for: episodeID)
        async let _ = playbackUseCase.play(episode: episode)

        return Output(
            episode: episode,
            artwork: await artwork
        )
    }
    
    func forPodcast(_ podcastId: NSManagedObjectID) async throws -> [EpisodeRecord] {
        return await episodeRepo.fetchAllforPodcast(for: podcastId)
    }
    
    func forUnlistened() async throws -> [EpisodeRecord] {
        let episodes = try await episodeRepo.fetchUnlistened()
        return episodes.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
    }
}
