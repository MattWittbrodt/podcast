//
//  Utils.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/22/25.
//

import Foundation
import CoreData
import AVKit

struct DateUtils {
    static func durationStringToSeconds(_ string: String) -> Int? {
        let components = string.components(separatedBy: ":")
        
        switch components.count {
        case 2:
            guard let minutes = Int(components[0]),
                  let seconds = Int(components[1]) else {
                return nil
            }
            return minutes * 60 + seconds
        case 3:
            guard let hours = Int(components[0]),
                  let minutes = Int(components[1]),
                  let seconds = Int(components[2]) else {
                return nil
            }
            return hours * 3600 + minutes * 60 + seconds
        default:
            return nil
        }
    }
}

func whereIsMySQLite() {
    let path = FileManager
        .default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .last?
        .absoluteString
        .replacingOccurrences(of: "file://", with: "")
        .removingPercentEncoding
    
    print(path ?? "Not found")
}

func formattedTime(time: Double ) -> String {
    let seconds = Int(time)
    //if seconds % 10 == 5 {updateLastListened()}
    let s = String(format: "%02d", seconds % 60)
    let m = String(format: "%02d", (seconds%3600)/60)
    if seconds < 3600 {
        return "\(m):\(s)"
    } else {
        return "\(seconds/3600):\(m):\(s)"
    }
}

func formatDate(time: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: time)
}

func shortTime(seconds: Int16) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}


func parseHtmlString(html: String) -> AttributedString {
    if let nsAttributedString = try? NSAttributedString(
        data: Data(html.utf8),
        options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
    ),
    let attributedString = try? AttributedString(nsAttributedString, including: \.uiKit) {
        attributedString
    } else {
        AttributedString(html)
    }
}

func deleteEpisode(episodeID: Int64) throws {
    guard let documentsDirectory = getDocumentsDirectory() else {
        throw DownloadError.invalidResponse
    }
    let uniqueFileName = "\(episodeID).mp3"
    let destinationUrl = documentsDirectory.appendingPathComponent(uniqueFileName)
        
    do {
        try FileManager.default.removeItem(at: destinationUrl)
        print("Deleted episode: \(destinationUrl)")
    } catch {
        throw DownloadError.deleteFailed
    }
}

// Add to your existing code
//private func getSharedDownloadsDirectory() -> URL {
//    let groupID = "group.mattwTest.podcast" // Must match your App Group
//    let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
//    return containerURL.appendingPathComponent("Downloads")
//}

// Call this once at app launch
func setupSharedDirectory() {
    let sharedDir = downloadDataUtils.getSharedDownloadsDirectory()
    try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true)
}

private func getDocumentsDirectory() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

func loadImageFromWeb(url: String) async throws -> Data? {
    guard url != "" else { return nil }
    do {
        let fixedString = url
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "%2C")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let fixedUrl = URL(string: fixedString) {
            let (data, _) = try await URLSession.shared.data(from:fixedUrl)
            return data
        } else {
            print("Failed to create URL from: \(fixedString)")
            throw ImageError.badUrl("Failed to create URL from: \(fixedString)")
        }
    } catch {
        print("Fetch imgage error: \(error)")
        throw ImageError.fetchImage(error)
    }
}

func upgradeToHTTPS(urlString: String) -> String? {
    guard var components = URLComponents(string: urlString) else { return nil }
    
    // Force HTTPS if scheme is HTTP
    if components.scheme?.caseInsensitiveCompare("http") == .orderedSame {
        components.scheme = "https"
    }
    
    return components.url?.absoluteString
}



struct FileManagerHelper {
    static func listFiles(in directory: URL) -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )
            return fileURLs
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
            return []
        }
    }
    
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
