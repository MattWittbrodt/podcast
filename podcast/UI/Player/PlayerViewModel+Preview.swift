//
//  PlayerViewModel+Preview.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/8/26.
//

import Foundation
import UIKit

#if DEBUG

extension PlayerViewModel {
    static var preview: PlayerViewModel {
        let vm = PlayerViewModel(
            useCase: .preview,
            playbackManager: PlaybackManager(),
            loadEpisodeUseCase: .preview,
            setEpisodeAsListenedUseCase: .preview,
            playbackUseCase: .preview
        )
        // Seed with fake data
        vm.currentEpisode = .preview
        vm.currentEpisodeImage = UIImage(systemName: "music.note")
        vm.playbackRate = 1.0
        vm.phase = .playing
        return vm
    }
}
#endif
