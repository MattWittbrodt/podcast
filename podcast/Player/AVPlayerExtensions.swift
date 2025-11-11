//
//  AVPlayerExtensions.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/18/25.
//


import AVKit
extension AVPlayer {
    var isPlaying: Bool { return rate != 0 && error == nil }
}
