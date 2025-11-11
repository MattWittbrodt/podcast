//
//  MockPlayerViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/22/25.
//

import Foundation
import MediaPlayer
import Combine
import CoreData

final class MockPlayerViewModel: PlayerViewModelProtocol {
    @Published var currentEpisode: Episode? = Episode.example
    @Published var episodeImageData: Data?
    @Published var playerState: PlayerState = .playing
    @Published var showFullPlayer: Bool = false
    @Published var duration: Int16 = 180*60
    
    @Published var message: String = ""
    
    @Published var playbackRate: Float = 1.0 //PlaybackRate = PlaybackRate(value: 1.0, label: "1.0x")
    @Published var currentTime = CMTime(value: 0, timescale: 1)
    
    var currentTimePublisher: AnyPublisher<CMTime, Never> {
        $currentTime.eraseToAnyPublisher()
    }
    
    var episodeImageDataPublisher: AnyPublisher<Data?, Never> {
        $episodeImageData.eraseToAnyPublisher()
    }
    
    @Published var context: NSManagedObjectContext
    
    @Published var hasChapters: Bool = false
    @Published var chapters: [Chapter]? = []
    @Published var currentChapter: Chapter?
        
    //var objectWillChange = ObservableObjectPublisher()
    
    init(context: NSManagedObjectContext) {
        if let url = Bundle.main.url(forResource: "sample_image", withExtension: "jpg") {
            self.episodeImageData = try? Data(contentsOf: url)
        }
        self.context = context
    }
    
    func playPause(alwaysPlay: Bool = false) {
        print("Mock playPause - \(self.playerState == .playing)")
        DispatchQueue.main.async {
            self.playerState = self.playerState == .playing ? .paused : .playing
        }        
    }
    
    func seek(seconds: Int64) {}
    
    func skipForward(seconds: Int64){}
    func skipBackward(seconds: Int64){}
    func updateRate(_ newRate: Float){}
    func setupPlayer(episode: Episode) async {}
    func cleanupPlayer() {}
    func updatePlaybackRate(_ rate: Float) {}
    func saveBookmark() {}
}
