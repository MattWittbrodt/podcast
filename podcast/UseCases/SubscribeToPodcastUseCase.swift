//
//  SubscribeToPodcastUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/23/26.
//

import Foundation

struct SubscribeToPodcastUseCase {
    let podcastRepository: PodcastRepository
    let episodeRepository: EpisodeRepository
    let downloadManager: DownloadManager
    
    func execute(podcastDetail: PodcastDetailDestination) async {
        let podcast = podcastRepository.createPodcastFromWeb(
            channel: podcastDetail.channel,
            feedUrl: podcastDetail.podcast.podcast.rssUrl()
        )
        
        do {
            guard let firstEpisode = try await episodeRepository.importEpisodes(from: podcastDetail.channel, for: podcast.objectID) else {
                return
            }
            Task {
                downloadManager.startDownload(for: firstEpisode)
            }
        } catch {
            print("Error adding episodes for \(podcast.title): \(error)")
        }
    }
    
}
