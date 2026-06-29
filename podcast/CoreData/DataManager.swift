//
//  CoreDataManager.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/13/25.
//

import Foundation
import CoreData
import AVKit

enum DataManagerError: Error {
    case episodeNotFound
    case chapterCreationError(Error)
}

@MainActor
@Observable
class DataManager: NSObject {
    let debugid = UUID()
    let persistence: PersistenceController
    
    var podcasts: [Podcast] = []
    var unlistenedEpisodes: [Episode] = [] {
        didSet {
            print("📡 unlistenedEpisodes changed to \(unlistenedEpisodes.count) items")
        }
    }
    
    private let episodeController: NSFetchedResultsController<Episode>
    private let podcastController: NSFetchedResultsController<Podcast>
    
    // For chapter updates. pushing to main thread
    typealias ChapterUpdateCompletion = @MainActor (Result<[Chapter]?, Error>) -> Void
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
        
        let episodeRequest = Episode.fetchRequest()
        episodeRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        episodeRequest.predicate = NSPredicate(format: "listened == false")
        
        // 2. Setup the Monitor
        self.episodeController = NSFetchedResultsController(
            fetchRequest: episodeRequest,
            managedObjectContext: persistence.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        // 1. Setup the Podcast Fetch Request
        let podcastRequest: NSFetchRequest<Podcast> = Podcast.fetchRequest()
        podcastRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Podcast.title_, ascending: true)]
        
        // 2. Setup the Podcast Monitor
        self.podcastController = NSFetchedResultsController(
            fetchRequest: podcastRequest,
            managedObjectContext: persistence.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        
        // 3. Start Monitoring
        self.episodeController.delegate = self
        self.podcastController.delegate = self
        
        try? episodeController.performFetch()
        try? podcastController.performFetch()
        
        // Initial population
        self.unlistenedEpisodes = episodeController.fetchedObjects ?? []
        self.podcasts = podcastController.fetchedObjects ?? []
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
    
    // Function does post-download cleanup. Currently handles updating episode duration as that often
    // conflicts with RSS
    private func handleFinishedDownload(guid: String, fileUrl: URL) {
        Task {
            do {
                let asset = AVURLAsset(url: fileUrl)
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)
                let finalDuration = durationSeconds.isFinite ? Int16(durationSeconds) : nil
                
                guard let updateDuration = finalDuration else {return}
                
                let context = persistence.container.newBackgroundContext()
                
                try await context.perform {
                    let request: NSFetchRequest<Episode> = Episode.fetchRequest()
                    request.predicate = NSPredicate(format: "guid == %@", guid)
                    
                    if let episode = try context.fetch(request).first {
                        episode.duration = updateDuration
                        try context.save()
                        print("Successfully saved duration for GUID: \(guid)")
                    }
                }
                
                // 3. Update the UI on the Main Actor
                await MainActor.run {
                    self.saveMainContext()
                }
            } catch {
                print("Error finalising download for \(guid): \(error.localizedDescription)")
            }
        }
    }
    
    func handleNewEpisodes(episodes: [Episode]) {
        let uniqueNewEpisodes = episodes.filter { newEpisode in
            !self.unlistenedEpisodes.contains(where: { $0.guid == newEpisode.guid })
        }
        
        // Update list with new episodes and then sort
        self.unlistenedEpisodes.append(contentsOf: uniqueNewEpisodes)
        sortEpisodesByTime()
    }
    
    func sortEpisodesByTime() {
        self.unlistenedEpisodes.sort { (episode1: Episode, episode2: Episode) in
            let date1 = episode1.publishedDate ?? Date.distantPast
            let date2 = episode2.publishedDate ?? Date.distantPast
            return date1 > date2
        }
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
    
    func markEpisodeAsManuallyDownloaded(_ episode: Episode) {
        episode.manualDownload = true
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

extension DataManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Any save anywhere in the app triggers this automatically
        DispatchQueue.main.async {
            //self.unlistenedEpisodes = self.fetchedResultsController.fetchedObjects ?? []
            // 4. Distinguish which controller updated
            if controller == self.episodeController {
                self.unlistenedEpisodes = self.episodeController.fetchedObjects ?? []
            } else if controller == self.podcastController {
                self.podcasts = self.podcastController.fetchedObjects ?? []
            }
        }
    }
}
