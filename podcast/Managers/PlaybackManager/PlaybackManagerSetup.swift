//
//  PlaybackManagerSetup.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import AVFoundation
import MediaPlayer

extension PlaybackManager {
    func setupAudioSession() {
        do {
            // Configure the audio session category
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(.playback, mode: .spokenAudio)
            
            // Activate the session
            try audioSession.setActive(true)
            
            // 3. Setup interruptions handling
            setupNotifications()
            
        } catch {
            print("Failed2 to setup audio session: \(error)")
        }
    }
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentEpisode?.episodeTitle ?? "Episode Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentEpisode?.podcastTitle ?? "Podcast Name"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Album"
        
        // Set artwork if available
        if let image = UIImage(named: "AlbumArt") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        //nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: Handle interruptions
    func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
            
        case .began:
            player.pause()
            isPlaying = false
            
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                player.rate = self.playbackRate
                isPlaying = true
            }
        default: ()
        }
    }
}

