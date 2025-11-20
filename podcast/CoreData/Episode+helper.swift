//
//  Episode+CoreDataProperties.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/26/25.
//
//

import Foundation
import CoreData

extension Episode {
    
    @discardableResult
    convenience init(title: String,
                     image: String,
                     episodeDescription: String,
                     publishedDate: Date,
                     enclosureUrl: String,
                     imageData: Data? = nil,
                     duration: Int16,
                     lastListened: Double = 0,
                     chaptersUrl: String?,
                     context: NSManagedObjectContext) {
        self.init(context: context)
        
        context.performAndWait {
            self.title = title
            self.imageUrl = image
            self.publishedDate = publishedDate
            self.enclosureUrl = enclosureUrl
            self.episodeDescription = episodeDescription
            self.duration = duration
            self.imageData = imageData
            self.lastListened = lastListened
        }
        if let chapters = chaptersUrl {
            self.chaptersUrl = chapters
        }
    }
    
    var formattedDate: String {
        publishedDate.map {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: $0)
        } ?? ""
    }
    
    static func allRecent() -> NSFetchRequest<Episode> {
        let request = Episode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        request.predicate = NSPredicate(format: "listened == false")
        return request
    }
    
    static func nextEpisode(current: Episode) -> NSFetchRequest<Episode> {
        let searchDate = current.publishedDate ?? Date.distantFuture
        let request = Episode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        request.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: \Episode.publishedDate),
            rightExpression: NSExpression(forConstantValue: current.publishedDate),
            modifier: .direct,
            type: .lessThan,
            options: []
        )
        request.fetchLimit = 1
        return request
    }
    
    static func allEpisodes(_ predicate: NSPredicate = .all) -> NSFetchRequest<Episode> {
        let request = Episode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Episode.publishedDate, ascending: false)]
        request.predicate = NSPredicate(format: "downloaded == true")
        return request
    }
    
    // Updates chapters by first checking version
    func updateChapters(context: NSManagedObjectContext) async throws {
        if let url = self.chaptersUrl {
            do {
                let decoded = try await decodeChapters(urlString: url)
                
                guard decoded.chapters.count != self.chapter?.count ?? 0 else {
                    return
                }
                
                // Remove current chapters before adding new ones
                if let chapters = self.chapter as? Set<Chapter> {
                    for chapter in chapters {
                        context.delete(chapter)
                    }
                }
                
                for chapter in decoded.chapters {
                    let mapped = await Chapter.fromWeb(chapter: chapter, context: context)
                    mapped.episode = self
                }
                try? context.save()
            } catch {
                throw error
            }
        }
    }
    
    static func handleListened(episode: Episode) async -> downloadDataResponse {
        episode.listened = true
        return await downloadDataUtils.deleteDownloadedFile(episodeId: episode.downloadId)
    }
    
    // Sorted chapters
    var sortedChapters: [Chapter] {
        guard let chapters = self.chapter as? Set<Chapter> else {
            return []
        }
        return chapters.sorted { $0.startTime < $1.startTime }
    }
    
    static var example: Episode {
        let context = PersistenceManager().viewContext
        return Episode(title: "1748 - Brain Rot",
                       image: "https://noagendaassets.com/enc/1742507331.163_na-1748-art-feed.jpg",
                       episodeDescription: "No Agenda Episode 1748 - \"Brain Rot\" \"Brain Rot\" Executive Producers: Commodore Sir Onymous of Dogpatch and Lower Slobbovia</p>\n<p>Dame Becky Baroness, of the great katy prairie, protectorate of the gulf coast of texas</p>\n<p>Chap Williams</p>\n<p>Ryan Schubert Sir Scott the White Knight of Pottersville Village in Somerset, Taxachussets</p>\n<p>Baroness Sarah Ruppert</p>\n<p>Viscount Dude Named Jeff</p>\n<p>Associate Executive Producers:</p>\n<p>North Idaho Sanity Brigade Donation</p>\n<p>Anon</p>\n<p>Sir Paulie Bravo Blockman Bing",
                       publishedDate: Date(),
                       enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1748-2025-03-20-Final.mp3",
                       duration: 12632,
                       lastListened: 1234.56,
                       chaptersUrl: nil,
                       context: context)
    }
}

extension Episode {
    var episodeTitle: String {
        title ?? "Title Missing"
    }
    
    var downloadId: String {
        let rawString = uuid?.uuidString ?? guid ?? title ?? "Title Missing"
        return rawString.replacingOccurrences(of: "/", with: "")
    }
    
    var displayDescription: String {
        episodeDescription ?? "Description Missing"
    }
    
    var episodeDate: Date {
        publishedDate ?? Date()
    }
    
    var episodeDuration: Int16 {
        duration
    }
    
    var lastListenedTime: Int16 {
        Int16(lastListened)
    }
    
    var isListened: Bool {
        listened
    }
    
    var podcastImgData: Data? {
        return podcast?.imageData
    }
    
    var podcastTitle: String {
        podcast?.title ?? "Podcast Title Missing"
    }
    
}

//MARK: From RSSEpisode
extension Episode {
    
    func newFromRssEpisode(with episodeData: RSSEpisode) {
        self.uuid = UUID()
        self.title = episodeData.episodeTitle
        self.imageUrl = episodeData.imageUrl
        self.episodeDescription = episodeData.displayDescription
        self.publishedDate = episodeData.episodeDate
        self.enclosureUrl = episodeData.enclosureUrl
        self.duration = episodeData.episodeDuration
        self.chaptersUrl = episodeData.chaptersUrl
        self.imageData = episodeData.imageData
        self.guid = episodeData.guid
    }
}

//MARK: From v2
extension Episode {
    static func create(from episode: RSSEpisode, context: NSManagedObjectContext) -> Episode {
        let entity = Episode(context: context)
        entity.title = episode.episodeTitle
        entity.duration = episode.episodeDuration
        entity.enclosureUrl = episode.enclosureUrl ?? "No Enclosure"
        entity.chaptersUrl = episode.chaptersUrl
        entity.episodeDescription = episode.displayDescription
        entity.guid = episode.guid
        entity.imageUrl = episode.imageUrl
        entity.publishedDate = episode.episodeDate
        return entity
    }
    
    // Consolidates logic for the file name. Extension agnostic.
    func savedFileName() -> String {
        let episodeTitle = self.title?.replacingOccurrences(of: "/", with: "-") ?? "episode"
        return "\(episodeTitle)-\(self.guid ?? "Default Guid")"
    }
    
//    func isDownloaded() -> Bool {
//        return self.download != nil
//    }
}

#if DEBUG
extension Episode {
    static func sample(in context: NSManagedObjectContext) -> Episode {
        print("Creating sample episode")
        return create(from: RSSChannel.exampleEpisodes[0], context: context)
    }
}
#endif
