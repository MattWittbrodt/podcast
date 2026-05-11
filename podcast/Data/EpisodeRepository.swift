//
//  EpisodeRepository.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//
import CoreData

struct EpisodeRepository {
    let dataManager: DataManager
    
    @MainActor
    func getEpisode(for id: NSManagedObjectID) -> Episode? {
        return try? dataManager.persistence.viewContext.existingObject(with: id) as? Episode
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
            let backgroundContext = await dataManager.persistence.container.newBackgroundContext()
            
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
    
}
