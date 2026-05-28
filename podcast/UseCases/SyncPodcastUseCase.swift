//
//  SyncPodcastUseCase.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation
import CoreData

struct SyncPodcastUseCase {
    let feedService: PodcastFeedService
    let imageService: ImageService
    let repository: PodcastRepository

    func execute(for podcastId: NSManagedObjectID ) async {
        
        // 1. Get the string safely on the Main Actor
        let feedUrlString = await MainActor.run { () -> String? in
            return repository.getObjectFromId(for: podcastId)?.feedUrl?.upgradeToHTTPS
        }

        // 2. Validate and convert outside the closure
        guard let feedUrlString, let url = URL(string: feedUrlString) else { return }

        do {
            // 1. Fetch raw data (The Service just returns a 'Channel' struct)
            let channel = try await feedService.fetchChannel(for: url)
            
            // 2. Filter to find only new episodes
            // We do this on the MainActor because we are reading the podcast's episodes
            let newItems = await MainActor.run {
                return repository.filterNewItems(channel.items, for: podcastId)
            }

            // 2. Add images to the new episodes
            let episodesWithImages = await imageService.enrichEpisodesWithImages(for: newItems)
            
            // 3. Get podcast image
            let podcastImage = await imageService.getImageData(from: channel.imageUrl)

            // 3. Update everything in one database transaction
            await MainActor.run {
                repository.updatePodcastRecord(podcastId, channel: channel, image: podcastImage)
                repository.saveNewEpisodes(episodesWithImages, to: podcastId)
            }
        } catch {
            print("Sync failed: \(error)")
        }
    }
}
