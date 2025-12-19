//
//  Protocols.swift
//  podcast
//
//  Created by Matt Wittbrodt on 12/18/25.
//

import Foundation

protocol PresentationPodcast {
    var title: String { get }
    var author: String { get }
    var description: String { get }
    func rssUrl() -> String
}

struct IdentifiablePodcast: Identifiable {
    let id = UUID()
    let podcast: any PresentationPodcast

    init(_ podcast: any PresentationPodcast) {
        self.podcast = podcast
    }
}
