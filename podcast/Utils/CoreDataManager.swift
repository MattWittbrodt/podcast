////
////  CoreDataManager.swift
////  podcast
////
////  Created by Matt Wittbrodt on 3/30/25.
////
//
import Foundation
import CryptoKit
import CoreData
//
//enum DataError: Error {
//    case saveError
//    case podcastRetrieveError
//}
//

extension NSManagedObjectContext {
    var didSavePublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: self)
    }
}


struct CoreDataManager {

    private struct Update {
        let apply: (Podcast) -> Void
        
        init<T: Equatable>(keyPath: ReferenceWritableKeyPath<Podcast, T>, newValue: T) {
            self.apply = { podcast in
                if podcast[keyPath: keyPath] != newValue {
                    podcast[keyPath: keyPath] = newValue
                }
            }
        }
    }
    
    static func compareRssPodcast(podcast: Podcast, rss: RSSChannel) {
        let updates = [
            Update(keyPath: \.title, newValue: rss.title),
            Update(keyPath: \.podcastDescription, newValue: rss.description),
            Update(keyPath: \.imageUrl, newValue: rss.imageUrl),
            Update(keyPath: \.author, newValue: rss.author),
        ]
        updates.forEach { $0.apply(podcast) }
    }
    
    // Runs async operations for each podcast
    static func getPodcastChannelData(urlString: String) async -> (RSSChannel?,Int64?) {
        let rssParser = RSSFeedParser()
        guard let urlString = upgradeToHTTPS(urlString: urlString), let url = URL(string: urlString) else {return (nil,nil)}
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {return (nil,nil)}
        
        let channelData: RSSChannel? = try? await rssParser.parse(from: url, data: data)
        return (channelData,Int64(data.count))
    }
    
//    static func updatePodcast(podcast: Podcast, context: NSManagedObjectContext) async {
//        let DOWNLOAD_COUNT = 3
//        let rssParser = RSSFeedParser()
//        
//        
//        // First, parse RSS feed
//        Thread.callStackSymbols.forEach { print($0) }
//        guard let urlString = upgradeToHTTPS(urlString: podcast.feedUrl ?? ""), let url = URL(string: urlString) else {return}
//        guard let (data, _) = try? await URLSession.shared.data(from: url) else {return}
//        // Check size of data. If it matches previous, then just return
//        guard data.count != podcast.rssData else {return}
//        podcast.rssData = Int64(data.count)
//        
//        let channelData: RSSChannel? = try? await rssParser.parse(from: url, data: data)
//        
//        // Check if response. Start by updating podcast with any relevant information
//        guard let channelData = channelData else {return}
//        let updates = [
//            Update(keyPath: \.title, newValue: channelData.title),
//            Update(keyPath: \.podcastDescription, newValue: channelData.description),
//            Update(keyPath: \.imageUrl, newValue: channelData.imageUrl),
//            Update(keyPath: \.author, newValue: channelData.author),
//        ]
//        updates.forEach { $0.apply(podcast) }
//        
//        // Add image data
//        if let imageUrlString = podcast.imageUrl {
//            podcast.imageData = try? await loadImageFromWeb(url: imageUrlString)
//        }
//        
//        // Get episidoes and add new to podcast
//        do {
//            let RssEpisodes = channelData.items
//            
//            if let existingEpisodes = podcast.episodes {
//                let existingIds = Set(existingEpisodes.compactMap { ($0 as AnyObject).value(forKey: "guid") as? String})
//                // Finds Ids not in set. With those, create episode class and link with podcast
//                let unsavedEpisodes = RssEpisodes.filter { !existingIds.contains(String($0.guid)) }
//                for episodeToSave in unsavedEpisodes {
//                    var forSaving = episodeToSave
//                    let ep = Episode(context: context)
//                    forSaving.imageData = try? await loadImageFromWeb(url: episodeToSave.imageUrl)
//                    ep.configure(with: episodeToSave)
//                    ep.listened = false
//                    ep.podcast = podcast
//                    
//                    if ep.chaptersUrl != nil {
//                        try? await ep.updateChapters(context: context)
//                    }
//                }
//                try? context.save()
//                
//                // Updating chapters for other episodes
//                let existingEpisodeArray = existingEpisodes.allObjects as? [Episode] ?? []
//                
//                for episode in existingEpisodeArray {
//                    if episode.chaptersUrl != nil && episode.listened == false {
//                        try? await episode.updateChapters(context: context)
//                    }
//                }
//                
//            }
//        }
//        
//        // Next, figure out which to download
//        let toDownload = podcast.episodes?
//            .compactMap { $0 as? Episode }
//            .sorted { (episode1: Episode, episode2: Episode) in
//                episode1.publishedDate ?? Date.distantPast > episode2.publishedDate ?? Date.distantPast
//            }
//            .prefix(DOWNLOAD_COUNT)
//        
//        for episode in toDownload ?? [] {
//            if episode.downloaded { continue } else {
//                do {
//                    let url = try await handleEpisodeData(episode: episode, context: context)
//                    episode.downloaded = true
//                } catch {
//                    print(error)
//                }
//            }
//        }
//    }
}




//struct CoreDataManager  {
//    let networkManager = NetworkManager()
//    
//    func getPodcast(feedId: Int, context:NSManagedObjectContext) async -> Result<Podcast,DataError> {
//        let request: NSFetchRequest<Podcast> = Podcast.fetchRequest()
//        request.predicate = NSPredicate(format: "feedId == %d", feedId)
//        do {
//            let results = try context.fetch(request)
//            if results.count == 1 {
//                return .success(results[0])
//            } else {
//                return .failure(DataError.podcastRetrieveError)
//            }
//        } catch {
//            return .failure(DataError.podcastRetrieveError)
//        }
//    }
//    
//    private struct Update {
//        let keyPath: ReferenceWritableKeyPath<Podcast, String>
//        let newValue: String
//    }
//    
//    static func updatePodcast(podcast: Podcast, context: NSManagedObjectContext) async {
//        let DOWNLOAD_COUNT = 3
//        let networkManager = NetworkManager()
//        //let apiFeedId = Int(podcast.feedId)
//        
//        // Get podcast from index, check if there are podcast-level updates
//        //let podcastFetch = await networkManager.fetchPodcastByFeed(feed: apiFeedId)
//        switch podcastFetch {
//        case .success(let fromApi):
//            
//            let updates = [
//                Update(keyPath: \.title, newValue: fromApi.title),
//                Update(keyPath: \.author, newValue: fromApi.author),
//                Update(keyPath: \.podcastDescription, newValue: fromApi.description),
//                Update(keyPath: \.image, newValue: fromApi.image)
//            ]
//            
//            updates.forEach { update in
//                if podcast[keyPath: update.keyPath] != update.newValue {
//                    podcast[keyPath: update.keyPath] = update.newValue
//                }
//            }
//        case .failure(let error):
//            print("Error with update Podcast: \(error)")
//        }
//        
//        // Get episidoes and add new to podcast
//        do {
//            let episodeFetch = try await networkManager.fetchEpisodesByFeedId(id: apiFeedId)
//            if let existingEpisodes = podcast.episodes {
//                
//                let existingIds = Set(existingEpisodes.compactMap { ($0 as AnyObject).value(forKey: "id") as? Int64})
//                // Finds Ids not in set. With those, create episode class and link with podcast
//                let unsavedEpisodes = episodeFetch.filter { !existingIds.contains(Int64($0.id)) }
//                for episode in unsavedEpisodes {
//                    let imageData: Data? = try? await loadImageFromWeb(url: episode.image)
//                    let newEpisode = Episode(
//                        episodeId: Int64(episode.id),
//                        title: episode.title,
//                        image: episode.image,
//                        episodeDescription: episode.description,
//                        publishedDate: episode.datePublished,
//                        enclosureUrl: episode.enclosureUrl,
//                        imageData: imageData,
//                        duration: episode.duration,
//                        chaptersUrl: episode.chaptersUrl,
//                        listened: false,
//                        context: context)
//                    newEpisode.podcast = podcast
//                    
//                    if episode.chaptersUrl != nil {
//                        try? await newEpisode.updateChapters(context: context)
//                    }
//                    
//                }
//                try? context.save()
//            }
//        } catch {
//            print("Error updating... \(error)")
//        }
//        
//        // Next, figure out which to download
//        let toDownload = podcast.episodes?
//            .compactMap { $0 as? Episode }
//            .sorted { (episode1: Episode, episode2: Episode) in
//                episode1.publishedDate > episode2.publishedDate
//            }
//            .prefix(DOWNLOAD_COUNT)
//        for episode in toDownload ?? [] {
//            if episode.downloaded { continue } else {
//                do {
//                    let url = try await handleEpisodeData(episode: episode, context: context) //downloadEpisodetoFile(episode: episode)//, withFileName: String(episode.id))
//                    episode.downloaded = true
//                } catch {
//                    print(error)
//                }
//            }
//        }
//    }
//}
