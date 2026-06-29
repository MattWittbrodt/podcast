//
//  EpisodeRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//
import CoreData

class EpisodeRepository {
    let dataManager: DataManager
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
    
    @MainActor
    func getEpisode(for id: NSManagedObjectID) -> Episode? {
        return try? context.existingObject(with: id) as? Episode
    }
    
    @MainActor func getRecentEpisodesForEachPodcast(limit: Int) -> [Episode] {
        // Checking for unlistened episodes that are not downloaded
        let groupedByPodcast = Dictionary(grouping: dataManager.unlistenedEpisodes, by: { $0.podcast?.title ?? "Unknown Podcast" })

        // Map over each group to sort and take the top n
        let topNEpisodes = groupedByPodcast.mapValues { episodes in
            episodes
                .sorted { $0.publishedDate ?? .distantPast > $1.publishedDate ?? .distantPast}
                .prefix(limit)
        }.values.flatMap { $0 }
        
        return topNEpisodes
    }
    
    @MainActor func getAllUnlistenedEpisodes() -> [Episode] {
        return dataManager.unlistenedEpisodes
    }
    
    @MainActor func getUnlistenedEpisodesWithChapters() throws -> [Episode] {
        let fetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
        let unlistenedPredicate = NSPredicate(format: "listened == NO")
        let chaptersUrlPredicate = NSPredicate(format: "chaptersUrl != NULL")
        let compoundPredicate = NSCompoundPredicate(
            type: .and,
            subpredicates: [unlistenedPredicate, chaptersUrlPredicate]
        )
        fetchRequest.predicate = compoundPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        return try dataManager.persistence.viewContext.fetch(fetchRequest)
    }
    
    func updateChapters(for episodeID: NSManagedObjectID, with chapterInfos: [ChapterInfo]) async throws {
        
        Task.detached {
            // Create a new, private context for this single transaction
            let backgroundContext = await self.dataManager.persistence.container.newBackgroundContext()
            
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
                        
            try await backgroundContext.perform {
                // 1. Fetch the necessary parent object SAFELY in THIS context
                guard let episodeInContext = backgroundContext.object(with: episodeID) as? Episode else {
                    throw DataManagerError.episodeNotFound
                }
                
                episodeInContext.chapters = nil
                print("removed chapters for: \(episodeInContext.title ?? "title missing")")
                
                for chapterInfo in chapterInfos {
                    let chapter = Chapter.fromWeb(chapter: chapterInfo, context: backgroundContext)
                    chapter.episode = episodeInContext
                }
                
                try backgroundContext.save()
                print("Successfully saved new chapters for: \(episodeInContext.title ?? "title missing")")
            }
        }
    }
    
    // Marks and episode as manually downloaded by user
    func markAsManuallyDownloaded(_ episode: Episode) {
        context.perform {
            episode.manualDownload = true
        }
        save()
    }
    
    // Marks and episode as listened
    @MainActor
    func markEpisodeAsListened(_ id: NSManagedObjectID) {
        let context = self.context
        
        context.perform { [context] in
            guard let episode = try? context.existingObject(with: id) as? Episode else {
                return
            }
            episode.listened = true
            episode.lastListened = Double(episode.duration)
            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }
    
    // Marks and episode as unlistened
    func markEpisodeAsUnlistened(_ episode: Episode) {
        context.perform {
            episode.listened = false
            episode.lastListened = 0
        }
        save()
    }
    
    // Updating the episode duration if the file exists
    func updateDurationFromFile(for episode: Episode, length: Int16) async {
        
        await context.perform {
            // Assuming your Core Data attribute is named 'fileLength' or similar
            episode.duration = length
            
            // Persist the change
            guard self.context.hasChanges else { return }
            try? self.context.save()
        }
    }
    
    // Gets all episodes for a specific podcast
    func getAllEpisodesForPodcast(_ podcast: Podcast) async throws -> [Episode] {
        let objectID = podcast.objectID
        
        return try await context.perform {
            guard let podcastOnThisThread = self.context.object(with: objectID) as? Podcast else {
                return []
            }
            
            let fetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "podcast == %@", podcastOnThisThread)
            
            return try self.context.fetch(fetchRequest)
        }
    }
    
    // Marks all episodes as listened for a podcast
    @MainActor
    func markAllEpisodesAsListened(for podcast: Podcast) {

        // 1. Create the Batch Request
        let batchRequest = NSBatchUpdateRequest(entityName: "Episode")
        
        // 2. Target only this podcast's episodes
        batchRequest.predicate = NSPredicate(format: "podcast == %@", podcast.objectID)
        
        // 3. Set the update dictionary
        batchRequest.propertiesToUpdate = ["listened": true]
        batchRequest.resultType = .updatedObjectIDsResultType

        do {
            let result = try context.execute(batchRequest) as? NSBatchUpdateResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []
            
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSUpdatedObjectsKey: objectIDs],
                into: [context]
            )
        } catch {
            print("Failed to batch update: \(error)")
        }
    }
    
    // Imports episodes to a podcast
    func importEpisodes(from channel: RSSChannel, for podcastID: NSManagedObjectID) async throws -> Episode? {
        
        return try await context.perform {
            guard let podcast = try self.context.existingObject(with: podcastID) as? Podcast else {
                return nil
            }
            
            var firstEpisode: Episode?
            
            for (index, item) in channel.items.enumerated() {
                let episode = Episode.create(from: item, context: self.context)
                episode.podcast = podcast
                
                // Default behavior is to treat the first episode as unlistened when subscribing
                if index == 0 {
                    episode.listened = false
                    firstEpisode = episode
                } else {
                    episode.listened = true
                }
            }
            
            // Save the whole batch at once
            if self.context.hasChanges {
                try self.context.save()
            }
            
            return firstEpisode
        }
    }
    
    @MainActor
    func fetchNextEpisode(after episodeID: NSManagedObjectID) async throws -> Episode? {
        // 1. Safely pull the thread-unsafe object into the current context using its thread-safe ID
        guard let currentEpisode = try context.existingObject(with: episodeID) as? Episode else {
            return nil
        }
        let request = NSFetchRequest<Episode>(entityName: "Episode")
        let referenceDate = currentEpisode.publishedDate ?? Date.distantPast
        request.predicate = NSPredicate(
            format: "publishedDate <= %@ AND listened = %@",
            referenceDate as CVarArg,
            NSNumber(value: false)
        )
        request.sortDescriptors = [NSSortDescriptor(key: "publishedDate", ascending: false)]
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
}
