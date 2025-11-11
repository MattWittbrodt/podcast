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
        guard components.count == 3,
              let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
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

func shortTime(seconds: Int16) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}


func htmlToPlainText(html: String) -> String? {
    guard let data = html.data(using: .utf8) else { return nil }
    
    do {
        let attributedString = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
        return attributedString.string
    } catch {
        print("Error converting HTML: \(error)")
        return nil
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
            throw ImageError.badUrl("Failed to create URL from: \(fixedString)")
        }
    } catch {
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
