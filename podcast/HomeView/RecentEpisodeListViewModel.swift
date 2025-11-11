////
////  RecentEpisodeListViewModel.swift
////  podcast
////
////  Created by Matt Wittbrodt on 6/28/25.
////
//
//import Foundation
//import CoreData
//
//@Observable class RecentEpisodesViewModel {
//    var episodes: [Episode] = []
//    var isLoading = false
//    var message: String = "demo"
//    private var persistenceManager: PersistenceManager
//    
//    func setup(persistenceManager: PersistenceManager) {
//        self.persistenceManager = persistenceManager
//    }
//    
//    func loadRecentEpisodes() async {
//        isLoading = true
//        defer {isLoading = false}
//        
//        do {
//            let fetched_episodes = try await self.persistenceManager?.viewContext.perform {
//                try self.persistenceManager?.viewContext.fetch(Episode.allRecent())
//            }
//            episodes = fetched_episodes ?? []
//            message = "Num episodes: \(episodes.count)"
//        } catch {
//            print("Error fetching episodes: \(error.localizedDescription)")
//        }
//    }
//    
//    @MainActor
//    func swipeDownload(_ episode: Episode) async {
//        do {
//            // Download image
//            guard let episodeUrl = episode.enclosureUrl else { return }
//            let download = try await downloadDataUtils.downloadEpisodetoFile(url: episodeUrl, episodeId: episode.downloadId)
//            if let newDuration = download.duration {
//                episode.duration = newDuration
//            }
//            episode.downloaded = true
//            try? self.persistenceManager?.viewContext.save()
//        } catch {
//            print("error downloading episode from swipe: \(error.localizedDescription)")
//        }
//    }
//    
//    @MainActor
//    func deleteAllChapters(context: NSManagedObjectContext) {
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Chapter")
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        
//        do {
//            try context.execute(batchDeleteRequest)
//            try context.save() // Save the context after batch delete
//            print("Deleted all chapters")
//        } catch {
//            print("Error deleting all chapters entities: \(error)")
//        }
//    }
//    
//    @MainActor
//    func updatePodcasts() async {
//        //guard let context = self.persistenceManager?.viewContext else { return }
//        guard let manager = self.persistenceManager else { return }
//        //deleteAllChapters(context: manager.viewContext)
//        
//        isLoading = true
//        defer {isLoading = false}
//        
//        let podcasts: [Podcast]
//        do {
//            podcasts = try await manager.viewContext.perform {
//                try manager.viewContext.fetch(Podcast.allSaved())
//            }
//        } catch {
//            podcasts = []
//            print("error fetching episodes")
//        }
//        
//        // Logging episodes to download
//        var episodeToDownload: [Episode] = []
//        
//        for podcast in podcasts {
//            let (channelData, dataCount) = await CoreDataManager.getPodcastChannelData(urlString: podcast.feedUrl!)
//            // need channel data, a value for count, and the count != previously stored
//            guard let channelData = channelData, let dataCount = dataCount, dataCount != podcast.rssData else { continue }
//            CoreDataManager.compareRssPodcast(podcast: podcast, rss: channelData)
//            
//            // Process episodes. Need to convert new RSS episodes to core data. Also need to remove episodes
//            // that shouldn't be downloaded.
//            do {
//                let RssEpisodes = channelData.items
//                
//                if let existingEpisodes = podcast.episodes {
//                    
//                    // ID existing episodes and episodes that have been downloaded
//                    let existingIds = Set(existingEpisodes.compactMap { ($0 as AnyObject).value(forKey: "guid") as? String})
//                    
//                    // Finds Ids not in set. With those, create episode class and link with podcast
//                    let unsavedEpisodes = RssEpisodes.filter { !existingIds.contains(String($0.guid)) }
//                    
//                    // Saving each unsaved episode and assigning podcast
//                    for episodeToSave in unsavedEpisodes {
//                        // Fetching the image data
//                        var forSaving = episodeToSave
//                        forSaving.imageData = try? await loadImageFromWeb(url: episodeToSave.imageUrl)
//                        
//                        let ep = Episode(context: manager.viewContext)
//                        ep.configure(with: episodeToSave)
//                        ep.podcast = podcast
//                    }
//                    try? manager.viewContext.save()
//                }
//            }
//            
//            // Handling files here - delete and specifying which to download
//            let allEpisodes = podcast.episodes?
//                .compactMap { $0 as? Episode }
//                .filter { $0.listened == false }
//                .sorted { (episode1: Episode, episode2: Episode) in
//                    episode1.publishedDate ?? Date.distantPast > episode2.publishedDate ?? Date.distantPast
//                }
//            
//            let topToDownload = Array(allEpisodes?.prefix(3) ?? [])
//            episodeToDownload.append(contentsOf: topToDownload)
//            
//            let downloadedEpisodesToDelete = allEpisodes?
//                .dropFirst(3) // Skip the first 3 (already in top3ToDownload)
//                .filter { $0.downloaded == true && $0.lastListened == 0 && $0.listened == false } ?? []
//            
//            // Deleting episodes
//            for episodeToDelete in downloadedEpisodesToDelete {
//                let result = await downloadDataUtils.deleteDownloadedFile(episodeId: episodeToDelete.downloadId)
//                if result == downloadDataResponse.success {
//                    episodeToDelete.downloaded = false
//                } else {
//                    print("failed remove: \(result)")
//                }
//            }
//            try? manager.viewContext.save()
//        }
//        
//        // Before downloading, update new podast list
//        await loadRecentEpisodes()
//        
//        for episode in episodeToDownload {
//            guard episode.downloaded != true else { continue }
//            print("episode downloading: \(episode.title ?? "Unknown")")
//            do {
//                // Checking if image data is needed
//                let downloadImg = episode.imageData == nil && episode.image != ""
//                
//                if let imgUrl = episode.image {
//                    episode.imageData = try? await loadImageFromWeb(url: imgUrl)
//                }
//                
//                // Download image
//                guard let episodeUrl = episode.enclosureUrl else { continue }
//                let download = try await downloadDataUtils.downloadEpisodetoFile(url: episodeUrl, episodeId: episode.downloadId)
//                print(download)
//                if let newDuration = download.duration {
//                    episode.duration = newDuration
//                }
//                episode.downloaded = true
//            } catch {
//                print(error)
//            }
//            await loadRecentEpisodes()
//        }
//        try? manager.viewContext.save()
//    }
//    
//}
