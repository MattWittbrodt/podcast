//
//  TestData.swift
//  Planecastv2
//
//  Created by Matt Wittbrodt on 10/13/25.
//

import Foundation


extension RSSChannel {
    
    static var example: RSSChannel {
        return RSSChannel(
            title: "No Agenda Show",
            link: "http://noagendashow.nethttp://noagendashow.nethttp://trollroom.io",
            author: "Adam Curry & John C. DvorakAdam Curry & John C Dvorak",
            description: "Deconstructing Media with No Agenda, by Adam Curry and John C. DvorakDeconstructing Media with No Agenda, by Adam Curry and John C. Dvorak<p><strong>No Agenda Epsiode 1807 Live Sunday October 12th 2025 </strong><strong>Living Large and LIT!</strong></p>\n<p><strong>Boost us!</strong></p>\n<p><strong>Get a modern app at podcastapps.com</strong></p>\n<p>&nbsp;</p>",
            imageUrl: "https://noagendaassets.com/enc/1760304785.269_na-1807-art-feed.jpg",
            items: self.exampleEpisodes,
            podcastImageData: nil
        )
    }

    static var exampleEpisodes: [RSSEpisode] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Important for reliability
        
        return [
        RSSEpisode(episodeTitle: "1807 - \"Keyboard Warrior\"",
                    link: "http://1807.noagendanotes.com",
                    displayDescription: "This is the episode",
                    guid: "http://1807.noagendanotes.com",
                    imageUrl: "https://noagendaassets.com/enc/1760304785.269_na-1807-art-feed.jpg",
                    episodeDate: dateFormatter.date(from: "2025-10-12 21:41:37")!,
                    episodeDuration: 11130,
                    chapters: nil,
                    enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1807-2025-10-12-Final.mp3",
                    chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1807.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1807.noagendanotes.com",
        ),
        RSSEpisode(episodeTitle: "1806 - \"Gray Zone\"",
                   link: "http://1806.noagendanotes.com",
                   displayDescription: "This is the episode",
                   guid: "http://1806.noagendanotes.com",
                   imageUrl: "https://noagendaassets.com/enc/1760045391.887_na-1806-art-feed.jpg",
                   episodeDate: dateFormatter.date(from: "2025-10-09 21:34:10")!,
                   episodeDuration: 11397,
                   chapters: nil,
                   enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1806-2025-10-09-Final.mp3",
                   chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1806.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1806.noagendanotes.com"
        ),
        RSSEpisode(episodeTitle: "1805 - \"Hamburger Wine\"",
                   link: "http://1805.noagendanotes.com",
                   displayDescription: "This is the episode",
                   guid: "http://1805.noagendanotes.com",
                   imageUrl: "https://noagendaassets.com/enc/1759699726.117_na-1805-art-feed.jpg",
                   episodeDate: dateFormatter.date(from: "2025-10-05 21:33:53")!,
                   episodeDuration: 11146,
                   chapters: nil,
                   enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1805-2025-10-05-Final.mp3",
                   chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1805.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1805.noagendanotes.com"
        ),
        RSSEpisode(episodeTitle: "1804 - \"Mucho Retardo\"",
                    link: "http://1804.noagendanotes.com",
                    displayDescription: "This is the episode",
                    guid: "http://1804.noagendanotes.com",
                    imageUrl: "https://noagendaassets.com/enc/1759440112.979_na-1804-art-feed.jpg",
                    episodeDate:  dateFormatter.date(from: "2025-10-02 21:27:12")!,
                    episodeDuration: 10922,
                   chapters: nil,
                   enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1804-2025-10-02-Final.mp3",
                   chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1804.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1804.noagendanotes.com"
        ),
        RSSEpisode(episodeTitle: "1803 - \"Drone Wall\"",
                     link: "http://1803.noagendanotes.com",
                     displayDescription: "This is the episode",
                     guid: "http://1803.noagendanotes.com",
                     imageUrl: "https://noagendaassets.com/enc/1759095154.717_na-1803-art-feed.jpg",
                     episodeDate: dateFormatter.date(from: "2025-09-28 21:40:14")!,
                     episodeDuration: 11179,
                     chapters: nil,
                     enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1803-2025-09-28-Final.mp3",
                     chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1803.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1803.noagendanotes.com",
        ),
        RSSEpisode(episodeTitle: "1802 - \"Stimming\"",
                   link: "http://1802.noagendanotes.com",
                   displayDescription: "This is the episode",
                   guid: "http://1802.noagendanotes.com",
                   imageUrl: "https://noagendaassets.com/enc/1758837928.804_na-1802-art-feed.jpg",
                   episodeDate: dateFormatter.date(from: "2025-09-25 22:11:20")!,
                   episodeDuration: 12793,
                   chapters: nil,
                   enclosureUrl: "https://op3.dev/e/mp3s.nashownotes.com/NA-1802-2025-09-25-Final.mp3",
                   chaptersUrl: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1802.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1802.noagendanotes.com"
        )]
    }
    
}
