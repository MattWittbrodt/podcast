//
//  BookmarkAudioManager.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 7/15/26.
//

import AVKit

final class BookmarkPlaybackManager {
    private let player = AVPlayer()
    private let playbackManager: PlaybackManager
    var isPlaying: Bool = false
    
    init(playbackManager: PlaybackManager) {
        self.playbackManager = playbackManager
    }
    
    func play(_ bookmark: BookmarkRecord) {
        playbackManager.pause()
        
        let item = AVPlayerItem(url: bookmark.audioFilePath)
        player.replaceCurrentItem(with: item)
                
        // Seek to start time if from episode
        if bookmark.isAudioFromEpisode {
            let startTime = CMTime(seconds: bookmark.startTime, preferredTimescale: 600)
            player.seek(to: startTime)
        }
        
        // Stop after 2 minutes
        let endTime = CMTime(seconds: bookmark.startTime + 120, preferredTimescale: 600)
        print("end time: \(endTime)")
        player.currentItem?.forwardPlaybackEndTime = endTime
        
        player.play()
        isPlaying = true
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }
    
    func stop() {
        player.currentItem?.forwardPlaybackEndTime = .invalid  // reset
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        playbackManager.resume()
    }
}
