//
//  EpisodeListProtocol.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/22/25.
//

import Foundation

//protocol DisplayableEpisode {
//    var episodeTitle: String { get }
//    var displayDescription: String { get }
//    var imageData: Data? { get }
//    var episodeDate: Date { get }
//    var isDownloaded: Bool { get }
//    var episodeDuration: Int16 { get }
//    var lastListenedTime: Int16 { get }
//    var isListened: Bool { get }
//    var podcastImgData: Data? { get }
//    var podcastTitle: String { get }
//}

//extension DisplayableEpisode {
//    var formattedDate: String {
//        let date_delta = Calendar.current.dateComponents([.day], from: episodeDate, to: Date()).day ?? 99
//        switch date_delta {
//            case 0:
//                return "Today"
//            case 1:
//                return "Yesterday"
//        case 2...6:
//            return "\(date_delta) days ago"
//        case 7:
//            return "1 Week Ago"
//        default:
//            let formatter = DateFormatter()
//            formatter.dateFormat = "MMM d"  // "Jan 15" format
//            return formatter.string(from: episodeDate)
//        }
//    }
//}

//class ObservableDisplayEpisode: ObservableObject {
//    @Published var episode: DisplayableEpisode
//    
//    init(episode: DisplayableEpisode) {
//        self.episode = episode
//    }
//}
