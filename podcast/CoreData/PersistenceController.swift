//
//  PersistenceController.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/30/25.
//

import Foundation
import CoreData

final class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    @Published var unlistenedEpisodes: [Episode] = []
    var playlist: [Episode]
    
    init(inMemory:Bool = false) {
        self.container = NSPersistentContainer(name: "UserData")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load stores synchronously for initialization
        var loadError: NSError?

        self.playlist = []
        Task {
            await loadUnlistenedEpisodes()
        }
        
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
            
            // Optional: Configure auto-merge for background saves
            self?.container.viewContext.automaticallyMergesChangesFromParent = true
            self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        // Verify the context is properly connected
        if container.viewContext.persistentStoreCoordinator == nil {
            let error = loadError ?? NSError(domain: "CoreData", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to connect persistent store coordinator"])
            fatalError("Bad loading: \(error)")
        }

    }
    
    func loadUnlistenedEpisodes() async {
        do {
            unlistenedEpisodes = try await self.viewContext.perform {
                try self.viewContext.fetch(Episode.allRecent())
            }
        } catch {
            print("Error fetching episodes: \(error.localizedDescription)")
        }
        print("Num episodes: \(unlistenedEpisodes.count)")
    }
    
    // Helper method for background operations
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
        
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask(block)
    }
    
    //MARK: - SwiftUI preview helper
//    static var preview: PersistenceController = {
//        let controller = PersistenceController(inMemory: true)
//        let context = controller.container.viewContext
//        
//        let testPodcast = Podcast(
//            title: "Podcasting 2.0 - The Future",
//            author: "Adam Curry & Dave Jones",
//            image: "https://noagendaassets.com/enc/1684513486.722_pcifeedimage.png",
//            podcastDescription: "The Podcast Index presents Podcasting 2.0 - Upgrading Podcasting",
//            feedUrl: "https://feeds.podcastindex.org/pc20.xml",
//            context: context
//        )
//        
//        let episode = Episode(
//            title: "1757 - \"Word Veto\"",
//            image: "https://noagendaassets.com/enc/1745186109.776_na-1757-art-feed.jpg",
//            episodeDescription: "<h2>No Agenda Episode 1757 - \"Word Veto\"</h2>\n\n\n\n<p>\"Word Veto\"</p>\n<p>Executive Producers:</p>\n<p>Earl Christopher</p>\n<p>Commodore Sir Dude Named Ralph</p>\n<p>Chase Adams</p>\n<p>mfDx of Anjou</p>\n<p>Jessica Provencher</p>\n<p>Sir Stoner Boner</p>\n<p>Mary Massie</p>\n<p>The future Sir Friar Joe</p>\n<p>David Homoney</p>\n<p>Charles Boch</p>\n<p>David Arneson</p>\n<p>Associate Executive Producers:</p>\n<p>Matthew Hodges</p>\n<p>Richard M</p>\n<p>Eli The Coffee Guy</p>\n<p>Pat Eckert</p>\n<p>Linda Lu Duchess of jobs and writer of...",
//            publishedDate: Date(),
//            enclosureUrl: "",
//            downloaded: true,
//            duration: 12866,
//            chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1757.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1757.noagendanotes.com",
//            context: context
//        )
//        
//        let episode2 = Episode(
//            title: "1756 - \"AG Barbie\"",
//            image: "https://noagendaassets.com/enc/1744926075.529_na-1756-art-feed.jpg",
//            episodeDescription: "<h2>No Agenda Episode 1756 - \"AG Barbie\"</h2>\n\n\n\n<p>\"AG Barbie\"</p>\n<p>Executive Producers:</p>\n<p>Sir Layron</p>\n<p>Sir Commodore J Stroke of ChupacabraCanoe (dot com)</p>\n<p>Ashley Williams</p>\n<p>Zach Williams</p>\n<p>Associate Executive Producers:</p>\n<p>Jeremy & Laura Brogan</p>\n<p>Anonymous</p>\n<p>Sir Ohiobloke</p>\n<p>Doug Wray</p>\n<p>Eli the coffee guy</p>\n<p>Ander Perez</p>\n<p>Linda Lu Duchess of jobs and writer of resumes</p>\n<p>Matthew Doolittle</p>\n<p>Become a member of the 1757 Club, support the show here</p>\n<p>Boost us with w...",
//            publishedDate: Date(), enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1756-2025-04-17-Final.mp3",
//            duration: 11752,
//            chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1756.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1756.noagendanotes.com",
//            context: context
//        )
//        
//        let testPodcast2 = Podcast(
//            title: "No Agenda Show",
//            author: "Adam Curry & John C. Dvorak",
//            image: "https://noagendaassets.com/enc/1745186109.776_na-1757-art-feed.jpg",
//            podcastDescription: "A show about politics with No Agenda, by Adam Curry and John C. Dvorak",
//            feedUrl: "http://feed.nashownotes.com/rss.xml",
//            context: context
//        )
//        
//        episode.podcast = testPodcast2
//        episode2.podcast = testPodcast2
//        
//        return controller
//    }()
}
