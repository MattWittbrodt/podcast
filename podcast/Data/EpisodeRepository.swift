//
//  EpisodeRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//
import CoreData

class EpisodeRepository {
    let dataManager: DataManager
    let downloadManager: DownloadManager
    private let context: NSManagedObjectContext

    init(dataManager: DataManager,
         context: NSManagedObjectContext,
        downloadManager: DownloadManager
    ) {
        self.dataManager = dataManager
        self.context = context
        self.downloadManager = downloadManager
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
    
    func fetchUnlistened() async throws -> [EpisodeRecord] {
        let cdEpisodes = try await dataManager.persistence.container.performBackgroundTask { context in
            let request = Episode.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
            request.predicate = NSPredicate(format: "listened == false")
            
            return try context.fetch(request)
        }
            
        var episodes: [EpisodeRecord] = []
        for episode in cdEpisodes {
            guard let formatted = await self.fetchForPlayback(for: episode.objectID) else { continue }
            episodes.append(formatted)
        }
        return episodes
    }
    
    @MainActor
    func getEpisode(for id: NSManagedObjectID) -> Episode? {
        return try? context.existingObject(with: id) as? Episode
    }
    
    @MainActor func getRecentEpisodesForEachPodcast(limit: Int) async -> [EpisodeRecord] {
        // Checking for unlistened episodes that are not downloaded
        let groupedByPodcast = Dictionary(grouping: dataManager.unlistenedEpisodes, by: { $0.podcast?.title ?? "Unknown Podcast" })

        // Map over each group to sort and take the top n
        let topNEpisodes = groupedByPodcast.mapValues { episodes in
            episodes
                .sorted { $0.publishedDate ?? .distantPast > $1.publishedDate ?? .distantPast}
                .prefix(limit)
        }.values.flatMap { $0 }
        
        var returnedEpisodes: [EpisodeRecord] = []
        for episode in topNEpisodes {
            guard let formatted = await self.fetchForPlayback(for: episode.objectID) else { continue }
            returnedEpisodes.append(formatted)
        }
        
        return returnedEpisodes
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
    func markAsManuallyDownloaded(_ id: NSManagedObjectID) async {
        
        await dataManager.persistence.container.performBackgroundTask { context in
            guard let episode = try? context.existingObject(with: id) as? Episode else {
                return
            }
            
            episode.manualDownload = true
            try? context.save()
        }
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
    func updateDurationFromFile(for episodeId: NSManagedObjectID, length: Int16) async {
        
        await dataManager.persistence.container.performBackgroundTask { context in
            guard let episode = try? context.existingObject(with: episodeId) as? Episode else {
                return
            }
            
            episode.duration = length
            try? context.save()
        }
    }
    
    // Imports episodes to a podcast
    func importEpisodes(from channel: RSSChannel, for podcastID: NSManagedObjectID) async throws -> EpisodeRecord? {
        
        let cdEpisode: NSManagedObjectID? = try await context.perform {
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
            
            return firstEpisode?.objectID
        }
        
        if let firstEpisode = cdEpisode {
            return await fetchForPlayback(for: firstEpisode)
        } else {
            return nil
        }
    }
    
    @MainActor
    func fetchNextEpisode(after episodeID: NSManagedObjectID) async throws -> EpisodeRecord? {
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
        
        guard let episode = try context.fetch(request).first else { return nil }
        
        return await self.fetchForPlayback(for: episode.objectID)
    }
    
    func updateLastListened(for id: NSManagedObjectID, time: Double) async {
        // 1. Spin up a temporary background thread context automatically
        await dataManager.persistence.container.performBackgroundTask { backgroundContext in
            
            // 2. Use the thread-safe ID to look up the object on THIS background thread
            guard let backgroundEpisode = try? backgroundContext.existingObject(with: id) as? Episode else {
                return
            }
                        
            // 3. Mutate the property safely in the background
            backgroundEpisode.lastListened = time
            
            // 4. Save directly to the disk on the background thread
            if backgroundContext.hasChanges {
                try? backgroundContext.save()
            }
        }
    }
    
    func getImageData(for id: NSManagedObjectID) async -> Data? {
        await dataManager.persistence.container.performBackgroundTask { backgroundContext in
            guard let backgroundEpisode = try? backgroundContext.existingObject(with: id) as? Episode else {
                return nil
            }
            return backgroundEpisode.getImageData()
        }
    }
    
    func getChaptersForId(for id: NSManagedObjectID) async -> [ChapterRecord] {
        await dataManager.persistence.container.performBackgroundTask { backgroundContext in
            guard let backgroundEpisode = try? backgroundContext.existingObject(with: id) as? Episode else {
                return []
            }
            
            // Sort chapters chronologically once here, in the background
            return (backgroundEpisode.chapters as? Set<Chapter>)?
                .map {
                    ChapterRecord(
                        imageData: $0.imageData,
                        imageUrl: $0.imageUrl,
                        startTime: $0.startTime,
                        chapterTitle: $0.chapterTitle
                    )
                }
                .sorted { $0.startTime < $1.startTime } ?? []
        }
    }
    
    func fetchForPlayback(for id: NSManagedObjectID) async -> EpisodeRecord? {
        let chapters = await self.getChaptersForId(for: id)
        let imgData = await self.getImageData(for: id)
        
        return await dataManager.persistence.container.performBackgroundTask { backgroundContext -> EpisodeRecord? in
            guard let backgroundEpisode = try? backgroundContext.existingObject(with: id) as? Episode else {
                print("Cannot turn into episode record")
                return nil
            }
            
            var audioUrl: URL
            if self.downloadManager.downloadFileExists(for: backgroundEpisode.savedFileName()) {
                audioUrl = self.downloadManager.getFullDownloadPath(for: backgroundEpisode.savedFileName())
            } else if let remoteUrlString = backgroundEpisode.enclosureUrl,
                      let remoteUrl = URL(string: remoteUrlString) {
                audioUrl = remoteUrl
            } else {
                return nil
            }
            
            return EpisodeRecord(
                objectId: id,
                episodeTitle: backgroundEpisode.title ?? "Episode title missing",
                podcastTitle: backgroundEpisode.podcast?.title ?? "Podcast title missing",
                playbackRate: backgroundEpisode.podcast?.playbackRate ?? 1.0,
                duration: backgroundEpisode.duration,
                lastListened: backgroundEpisode.lastListened,
                episodeDescription: backgroundEpisode.episodeDescription,
                audioUrl: audioUrl,
                chapters: chapters,
                guid: backgroundEpisode.guid,
                imgData: imgData,
                publishedDate: backgroundEpisode.publishedDate,
                enclosureUrl: backgroundEpisode.enclosureUrl,
                manualDownload: backgroundEpisode.manualDownload
            )
        }
    }
}
