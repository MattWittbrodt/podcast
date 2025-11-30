//
//  CoreDataManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/13/25.
//

import Foundation
import CoreData

enum DataManagerError: Error {
    case episodeNotFound
    case chapterCreationError(Error)
}

@MainActor
class DataManager: NSObject, ObservableObject {
    let debugid = UUID()
    let persistence: PersistenceManager
    
    @Published var podcasts: [Podcast] = []
    @Published var unlistenedEpisodes: [Episode] = [] {
        didSet {
            print("📡 unlistenedEpisodes changed to \(unlistenedEpisodes.count) items")
        }
    }
    
    // For chapter updates. pushing to main thread
    typealias ChapterUpdateCompletion = @MainActor (Result<[Chapter]?, Error>) -> Void
    
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        super.init()
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
    
    func handleNewEpisodes(episodes: [Episode]) {
        let uniqueNewEpisodes = episodes.filter { newEpisode in
            !self.unlistenedEpisodes.contains(where: { $0.guid == newEpisode.guid })
        }
        
        // Update list with new episodes and then sort
        self.unlistenedEpisodes.append(contentsOf: uniqueNewEpisodes)
        self.unlistenedEpisodes.sort { (episode1: Episode, episode2: Episode) in
            let date1 = episode1.publishedDate ?? Date.distantPast
            let date2 = episode2.publishedDate ?? Date.distantPast
            return date1 > date2
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
    
    @MainActor
    func refreshPodcasts() -> Void {
        do {
            podcasts = try loadSuscribedPodcasts()
        } catch {
            print("Error fetching podcasts")
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
    
    // Gets episodes with chapters to look for updates
    func loadUnlistenedEpisodesWithChapters() throws -> [Episode] {
        let fetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
        let unlistenedPredicate = NSPredicate(format: "listened == NO")
        let chaptersUrlPredicate = NSPredicate(format: "chaptersUrl != NULL")
        let compoundPredicate = NSCompoundPredicate(
            type: .and,
            subpredicates: [unlistenedPredicate, chaptersUrlPredicate]
        )
        fetchRequest.predicate = compoundPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        return try persistence.viewContext.fetch(fetchRequest)
    }
    
    func loadSuscribedPodcasts() throws -> [Podcast] {
        let podcastRequest: NSFetchRequest<Podcast> = Podcast.fetchRequest()
        podcastRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Podcast.title_, ascending: true)]
        return try persistence.viewContext.fetch(podcastRequest)
    }
    
    func getEpisodesForPodcast(for podcast: Podcast) throws -> [Episode] {
        let fetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "podcast == %@", podcast.objectID)
        return try persistence.viewContext.fetch(fetchRequest)
    }
}

// MARK: Data saving/updating functions
extension DataManager {
    func saveEpisodeToPodcast(_ episode: RSSEpisode, for podcast: Podcast) -> Episode {
        let newEpisode = Episode.create(from: episode, context: persistence.viewContext)
        
        newEpisode.podcast = podcast
        try? persistence.viewContext.save()
        return newEpisode
    }
    
    func markEpisodeAsListened(_ episode: Episode) {
        episode.listened = true
        unlistenedEpisodes.removeAll { listEpisode in
            listEpisode.guid == episode.guid
        }
        try? persistence.viewContext.save()
    }
    
    func markEpisodeAsUnlistened(_ episode: Episode) {
        episode.listened = false
        try? persistence.viewContext.save()
        do {
            unlistenedEpisodes = try loadunlistenedEpisodes()
        } catch {
            print("Failed to mark as unlistened.")
        }
    }
    
    func saveEpisodeTime(_ episode: Episode, time: Double) {
        episode.lastListened = time
        try? persistence.viewContext.save()
    }
    
    func updatePodcastRate(_ podcast: Podcast, rate: Float) {
        podcast.playbackRate = rate
        try? persistence.viewContext.save()
    }
    
    func saveMainContext() {
        self.persistence.viewContext.perform {
            do {
                if self.persistence.viewContext.hasChanges {
                    try self.persistence.viewContext.save()
                }
            } catch {
                print("❌ Could not save main context")
            }
        }
    }
}

//MARK: Chapter saving functions
extension DataManager {
    
    func updateEpisodesWithChapters() async {
        do {
            let chapterEpisodes = try self.loadUnlistenedEpisodesWithChapters()
            if !chapterEpisodes.isEmpty {
                print("Found \(chapterEpisodes.count) episodes with chapters to link...")
                for ep in chapterEpisodes {
                    do {
                        guard let chaptersUrl = ep.chaptersUrl,
                              let decodedChapters = try await PodcastFeedService.fetchNewChapters(for: chaptersUrl) else { continue }
                        try await self.updateChapters(for: ep.objectID, with: decodedChapters.chapters)
                    } catch {
                        print("Failed to get chapters for: \(ep.title ?? "podcast title missing")")
                    }
                }
            }
        } catch {
            print("Overall error: \(error)")
        }
    }
    
    func updateChapters(for episodeID: NSManagedObjectID, with chapterInfos: [ChapterInfo]) async throws {
        
        Task.detached {
            
            // Create a new, private context for this single transaction
            let backgroundContext = await self.persistence.container.newBackgroundContext()
            
            let needsUpdate = try await backgroundContext.perform {
                guard let episodeInContext = backgroundContext.object(with: episodeID) as? Episode else {
                    throw DataManagerError.episodeNotFound
                }
                // If chapter count is the same, no need to proceed with updates
                return episodeInContext.chapters?.count != chapterInfos.count
            }
            
            guard needsUpdate else {
                return // Chapters are already up-to-date, exit early
            }
            
            print("New chapters found, beginning download and update.")

            // If we reach here, then need to update chapters
            let chaptersWithImages = await withTaskGroup(of: ChapterInfo.self, returning: [ChapterInfo].self) { group in
                for chap in chapterInfos {
                    group.addTask {
                        var newChapWithData = chap
                        if let imgUrl = chap.img, let imgData = try? await loadImageFromWeb(url: imgUrl) {
                            newChapWithData.imgData = imgData
                        }
                        return newChapWithData
                    }
                }
                
                var newChapterInfos = [ChapterInfo]()
                for await result in group {
                    newChapterInfos.append(result)
                }
                return newChapterInfos
            }
            
            try await backgroundContext.perform {
                // 1. Fetch the necessary parent object SAFELY in THIS context
                guard let episodeInContext = backgroundContext.object(with: episodeID) as? Episode else {
                    throw DataManagerError.episodeNotFound
                }
                
                episodeInContext.chapters = nil
                print("removed chapters for: \(episodeInContext.title ?? "title missing")")
                
                for chapterInfo in chaptersWithImages {
                    let chapter = Chapter.fromWeb(chapter: chapterInfo, context: backgroundContext)
                    chapter.episode = episodeInContext
                }
                
                try backgroundContext.save()
                print("Successfully saved new chapters for: \(episodeInContext.title ?? "title missing")")
            }
        }
    }
}
