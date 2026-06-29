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
            
        let objectIDs: [NSManagedObjectID] = try await episodeRepo.dataManager.persistence.container.performBackgroundTask { context in
            guard let podcast = try? context.existingObject(with: podcastId) as? Podcast else {
                throw RepositoryError.notFound
            }
            
            let fetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "podcast == %@", podcast)
            
            return try context.fetch(fetchRequest).map { $0.objectID }
        }
        
        var records: [EpisodeRecord] = []
        for id in objectIDs {
            if let record = await episodeRepo.fetchForPlayback(for: id) {
                records.append(record)
            }
        }
        return records
    }
    
    func forUnlistened() async throws -> [EpisodeRecord] {
        let episodes = try await episodeRepo.fetchUnlistened()
        return episodes.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
    }
}
