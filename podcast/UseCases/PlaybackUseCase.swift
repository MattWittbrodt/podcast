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

struct PlaybackUseCase {
    let playbackManager: PlaybackManager
    let downloadManager: DownloadManager
    let episodeRepository: EpisodeRepository
    
    func play(episode: EpisodeRecord) async throws {
        do {
            await playbackManager.startPlayback(episode: episode)
        } catch {
            print("Error in starting episode playback")
        }
    }
}
