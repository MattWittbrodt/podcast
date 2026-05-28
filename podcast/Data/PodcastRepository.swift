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
    
    @MainActor func getObjectFromId(for podcastID: NSManagedObjectID) -> Podcast? {
        return try? dataManager.persistence.viewContext.existingObject(with: podcastID) as? Podcast
    }
    
    @MainActor
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
                
        // Save context if any change occurred
        if hasChanged {
            dataManager.saveMainContext()
        }
    }

    @MainActor
    func saveNewEpisodes(_ rssEpisodes: [RSSEpisode], to podcastId: NSManagedObjectID) {
        guard let podcast = self.getObjectFromId(for: podcastId) else { return }
    
        rssEpisodes.forEach {
            let _ = dataManager.saveEpisodeToPodcast($0, for: podcast)
        }
        
        dataManager.saveMainContext()
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
