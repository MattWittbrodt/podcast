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
            
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio, // Optimized for spoken content
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            
            // Activate the session
            try audioSession.setActive(true)
            
            // 3. Setup interruptions handling
            setupInterruptionHandling()
            
            // 4. Setup route change handling
//            setupRouteChangeHandling()
            
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
        
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentEpisode?.title ?? "Episode Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentEpisode?.podcast?.title ?? "Podcast Name"
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
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remove previous targets to avoid duplicates
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playPause()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playPause()
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: 30)
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 30)
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(seconds: Int64(event.positionTime))
            }
            return .success
        }
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
            
        case .began:
            // 🛑 INTERRUPTION STARTED
            print("Audio interrupted - pausing playback")
            
            // Save current playback state
//            wasPlayingBeforeInterruption = isPlaying
//            interruptionStartTime = currentTime
            
            // Pause playback but keep player ready to resume
            pause()
            
            // Update UI to show paused state
            playbackState = .paused
            
            
        case .ended:
            // ✅ INTERRUPTION ENDED
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // 🔊 SHOULD RESUME PLAYBACK
                print("Interruption ended - resuming playback")
                
                // The system wants us to resume (e.g., phone call ended)
//                play()
                
            } else {
                // 🔇 SHOULD NOT RESUME
                print("Interruption ended - keeping paused")
                // User might have explicitly paused during interruption
                // Or another app took over audio permanently
            }
            
        @unknown default:
            break
        }
    }
    
}

