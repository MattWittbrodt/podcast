//
//  PodcastRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//
import CoreData

class PodcastRepository {
    private let dataManager: DataManager
    private let context: NSManagedObjectContext

    init(dataManager: DataManager, context: NSManagedObjectContext) {
        self.dataManager = dataManager
        self.context = context
    }
    
    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Repo Save Error: \(error)")
            context.rollback()
        }
    }
    
    func fetchAll() async throws -> [PodcastRecord] {
        let context = self.context
        return try await context.perform {
            let request = Podcast.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "title_", ascending: true)]
            let results = try context.fetch(request)
            
            return results.map {
                PodcastRecord(
                    objectId: $0.objectID,
                    podcastTitle: $0.title,
                    author: $0.author,
                    imageData: $0.imageData,
                    imageUrl: $0.imageUrl,
                )
            }
        }
    }
    
    func getObjectFromId(for podcastID: NSManagedObjectID) -> Podcast? {
        return context.performAndWait {
            return try? context.existingObject(with: podcastID) as? Podcast
        }
    }
    
    func updatePodcastRecord(_ podcastId: NSManagedObjectID, channel: RSSChannel, image: Data?) {
        guard let podcast = self.getObjectFromId(for: podcastId) else { return }
        var hasChanged: Bool = false
        
        func applyUpdate<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<Podcast, Value>, newValue: Value) {
            if podcast[keyPath: keyPath] != newValue {
                podcast[keyPath: keyPath] = newValue
                hasChanged = true
            }
        }
        
        applyUpdate(\.title, newValue: channel.title)
        applyUpdate(\.author, newValue: channel.author)
        applyUpdate(\.podcastDescription, newValue: channel.description)
        applyUpdate(\.imageUrl, newValue: channel.imageUrl)
        
        // Update image data (non-key path logic remains)
        if let image, image != podcast.imageData {
            podcast.imageData = image
            hasChanged = true
        }
                
        if hasChanged {
            save()
        }
    }

    @MainActor
    func saveNewEpisodes2(_ rssEpisodes: [RSSEpisode], to podcastId: NSManagedObjectID) {
        guard let podcast = self.getObjectFromId(for: podcastId) else { return }
    
        rssEpisodes.forEach {
            let _ = dataManager.saveEpisodeToPodcast($0, for: podcast)
        }
        
        dataManager.saveMainContext()
    }
    
    // 2. Perform the entire operation on a background context
    func saveNewEpisodes(_ rssEpisodes: [RSSEpisode], to podcastId: NSManagedObjectID) async {
        await dataManager.persistence.container.performBackgroundTask { backgroundContext in
            
            // 3. Fetch the podcast localized to THIS background context
            guard let backgroundPodcast = try? backgroundContext.existingObject(with: podcastId) as? Podcast else {
                return
            }
            
            rssEpisodes.forEach { rssEpisode in
                // 4. CRITICAL: Pass the background context or ensure saveEpisodeToPodcast
                // uses the exact same 'backgroundContext' instance passed here.
                let _ = self.saveEpisodeToPodcast(rssEpisode, for: backgroundPodcast)
            }
            
            // 5. Save the background context changes so they merge up to the main context
            try? backgroundContext.save()
        }
    }
    
    func saveEpisodeToPodcast(_ episode: RSSEpisode, for podcast: Podcast) -> Episode {
        // 1. Grab whatever context the podcast is currently living in
        guard let context = podcast.managedObjectContext else {
            fatalError("Podcast must belong to a managed object context")
        }
        
        // 2. Create the episode in that EXACT same context
        let newEpisode = Episode.create(from: episode, context: context)
        
        // 3. This is now 100% thread-safe
        newEpisode.podcast = podcast
        
        // 4. Save that specific context
        try? context.save()
        return newEpisode
    }
    
    // Returns only new episodes
    @MainActor
    func filterNewItems(_ items: [RSSEpisode], for podcastID: NSManagedObjectID) -> [RSSEpisode] {
        // The Repository uses its internal dataManager to find the object
        guard let podcast = try? dataManager.persistence.viewContext.existingObject(with: podcastID) as? Podcast else {
            return []
        }
        
        let existingGuids = Set(podcast.episodesArray.map { $0.guid })
        let filtered = items.filter { !existingGuids.contains($0.guid) }
        return filtered
    }
    
    // Finds all subscribed podcasts
    @MainActor
    func getAllSubscribedPodcasts() -> [Podcast] {
        return self.dataManager.podcasts
    }
    
    // Creates a podcast from an RSS version
    func createPodcastFromWeb(channel: RSSChannel, feedUrl: String) -> Podcast {
        return Podcast.create(from: channel, feedUrl: feedUrl, context: context)
    }
    
    // Updates the playback rate for the podcast
    func updatePodcastRate(_ episodeId: NSManagedObjectID, rate: Float) {
        guard let episode = try? context.existingObject(with: episodeId) as? Episode else { return }
        guard let podcast = episode.podcast else { return }
        podcast.playbackRate = rate
        save()
    }
    
    func markAllEpisodesAsListened(for podcastId: NSManagedObjectID) async throws {
        let batchRequest = NSBatchUpdateRequest(entityName: "Episode")
        batchRequest.predicate = NSPredicate(format: "podcast == %@", podcastId)
        batchRequest.propertiesToUpdate = ["listened": true]
        batchRequest.resultType = .updatedObjectIDsResultType
        
        let viewContext = self.context
        
        try await dataManager.persistence.container.performBackgroundTask { context in
            let result = try context.execute(batchRequest) as? NSBatchUpdateResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []
            
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSUpdatedObjectsKey: objectIDs],
                into: [context, viewContext]
            )
        }
    }
}

// Handles checks for equivalency
extension PodcastRepository {
    // Checks fields in podcast and updates appropriately.
    private func updateProperty<Value: Equatable>(
        // NO inout here
        _ currentPodcast: Podcast,
        _ keyPath: WritableKeyPath<Podcast, Value>,
        newValue: Value
    ) -> (podcast: Podcast, changed: Bool) {
        
        var mutablePodcast = currentPodcast
        
        if mutablePodcast[keyPath: keyPath] != newValue {
            mutablePodcast[keyPath: keyPath] = newValue
            return (podcast: mutablePodcast, changed: true)
        }
        return (podcast: currentPodcast, changed: false)
    }
    
}
