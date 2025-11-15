//
//  CoreDataManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/13/25.
//

import Foundation
import CoreData

@MainActor
class DataManager: ObservableObject {
    let debugid = UUID()
    let persistence: PersistenceManager
    
    @Published var podcasts: [Podcast] = []
    @Published var unlistenedEpisodes: [Episode] = [] {
        didSet {
            print("📡 unlistenedEpisodes changed to \(unlistenedEpisodes.count) items")
            print("📡 DataManager instance: \(debugid)")
        }
    }
    
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        loadInitialData()
    }
    
    func loadInitialData() {
        do {
            let request = Podcast.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Podcast.title_, ascending: true)]
            podcasts = try persistence.viewContext.fetch(request)
            
            unlistenedEpisodes = try loadunlistenedEpisodes()
            print("Loading initiate data: \(unlistenedEpisodes.count) episodes")
        } catch {
            print("Error fetching podcasts")
        }
    }
    
    @MainActor
    func subscribeToPodcast(feedUrl: String, channel: RSSChannel) {
        let context = persistence.viewContext
        let podcast = Podcast.create(from: channel, feedUrl: feedUrl, context: context)
        channel.items.enumerated().forEach { index, episodeItem in
            let episode = Episode.create(from: episodeItem, context: context)
            episode.podcast = podcast
            // So all episodes don't show up on the playlist, mark all as true
            // Keep most recent episode "unlistened" and add to unlistened episodes
            if index == 0 {
                unlistenedEpisodes.append(episode)
            } else {
                episode.listened = true
            }
        }
        
        persistence.saveContext()
        podcasts.append(podcast)
    }
    
    func addNewEpisodes(_ rssEpisodes: [RSSEpisode], to podcast: Podcast) async -> [Episode] {
        print("📥 Adding \(rssEpisodes.count) episodes to \(podcast.title ?? "No title")")
        
        let context = persistence.viewContext
        
        var addedEpisodes: [Episode] = []
        for rssEpisode in rssEpisodes {
            let episode = Episode.create(from: rssEpisode, context: context)
            episode.podcast = podcast
            episode.listened = false
            addedEpisodes.append(episode)
        }
        persistence.saveContext()
        
        let beforeCount = await MainActor.run { self.unlistenedEpisodes.count }
        await MainActor.run {
            refreshEpisodes()
        }
        let afterCount = await MainActor.run { self.unlistenedEpisodes.count }
        
        print("🔄 Refresh completed - Before: \(beforeCount), After: \(afterCount)")
        
        return addedEpisodes
    }
    
    @MainActor
    func refreshEpisodes() -> Void {
        do {
            unlistenedEpisodes = try loadunlistenedEpisodes()
            print("🔄 Refreshed episodes list: \(unlistenedEpisodes.count) total episodes")
        } catch {
            print("Error fetching")
        }
    }
}

// MARK: Data access functions
extension DataManager {
    func loadunlistenedEpisodes() throws -> [Episode] {
        let episodeRequest = Episode.fetchRequest()
        episodeRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        episodeRequest.predicate = NSPredicate(format: "listened == false")
        return try persistence.viewContext.fetch(episodeRequest)
    }
    
    func loadSuscribedPodcasts() throws -> [Podcast] {
        let podcastRequest: NSFetchRequest<Podcast> = Podcast.fetchRequest()
        podcastRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Podcast.title, ascending: true)]
        return try persistence.viewContext.fetch(podcastRequest)
    }
    
}

// MARK: Data saving functions
extension DataManager {
    func saveEpisodeToPodcast(_ episode: RSSEpisode, for podcast: Podcast) -> Episode {
        let newEpisode = Episode.create(from: episode, context: persistence.viewContext)
        newEpisode.podcast = podcast
        try? persistence.viewContext.save()
        return newEpisode
    }
    
//    func saveDownload(_ episode: Episode, location: URL) {
//        let entity = DownloadedEpisode(context: persistence.viewContext)
//        entity.timestamp = Date()
//        entity.filename = location.lastPathComponent
//        print("Saved in: \(location.lastPathComponent)")
//        entity.episode = episode
//        try? persistence.viewContext.save()
//    }
}
