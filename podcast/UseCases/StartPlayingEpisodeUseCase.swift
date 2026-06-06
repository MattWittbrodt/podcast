//
//  StartPlayingEpisodeUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/1/26.
//

import Foundation
import CoreData

enum PlaybackError: Error {
    case episodeNotFound
    case noAudioUrl
}

struct StartPlayingEpisodeUseCase {
    let playbackManager: PlaybackManager
    let downloadManager: DownloadManager
    let episodeRepository: EpisodeRepository
    
    func execute(episodeId: NSManagedObjectID) async throws {
        do {
            guard let episode = await episodeRepository.getEpisode(for: episodeId) else { throw PlaybackError.episodeNotFound }
            
            // Checking that both download path can be created and
            var audioURL: URL
            if downloadManager.downloadFileExists(for: episode.savedFileName()) {
                audioURL = downloadManager.getFullDownloadPath(for: episode.savedFileName())
            } else if let remoteURLString = episode.enclosureUrl,
                     let remoteURL = URL(string: remoteURLString) {
                audioURL = remoteURL
            } else {
                throw PlaybackError.noAudioUrl
            }
            
            await playbackManager.startPlayback(episode: episode, location: audioURL)
            
        } catch {
            print("Error in starting episode playback")
        }
    }
}
