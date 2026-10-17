//
//  FilePathService.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/13/26.
//

import Foundation

final class FilePathService: Sendable {
    private let downloadsDirectory: URL
    
    // For testing, this allows us to pass a temp dir 
    init(downloadsDirectory: URL? = nil) {
        self.downloadsDirectory = downloadsDirectory ?? Self.setupDownloadsDirectory()!
        print("📁 downloads: \(self.downloadsDirectory.path)")
    }
    
    private static func setupDownloadsDirectory() -> URL? {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.planecast.Planecast") else {
            print("not found group")
            return nil
        }
        let downloadsURL = groupURL.appendingPathComponent("Downloads")
        
        // Attempt to create the directory
        do {
            try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
            return downloadsURL
        } catch {
            print("Error creating downloads directory: \(error.localizedDescription)")
            return nil
        }
    }
    
    func url(for bookmark: BookmarkRecord) -> URL {
        let fileName = "\(bookmark.savedFileName()).m4a"
        let sanitizedFileName = sanitizeFileName(fileName)
        return downloadsDirectory.appendingPathComponent(sanitizedFileName)
    }
    
    func url(for episode: EpisodeRecord) -> URL {
        let fileName = "\(episode.savedFileName()).mp3"
        let sanitizedFileName = sanitizeFileName(fileName)
        return downloadsDirectory.appendingPathComponent(sanitizedFileName)
    }
    
    func url(for downloadLocation: String) -> URL {
        let fileName = "\(downloadLocation).mp3"
        let sanitizedFileName = sanitizeFileName(fileName)
        return downloadsDirectory.appendingPathComponent(sanitizedFileName)
    }
    
    func findAllMP3sInDownloads() -> [URL] {
        let fileManager = FileManager.default
        
        do {
            let directoryContents = try fileManager.contentsOfDirectory(
                at: downloadsDirectory,
                includingPropertiesForKeys: nil,
                options: []
            )
            return directoryContents.filter { $0.pathExtension == "mp3" }
        } catch {
            print("Error finding MP3s: \(error)")
            return []
        }
    }
    
    func downloadFileExists(for relativePath: String) -> URL? {
        let sanitizedFileName = self.sanitizeFileName(relativePath)
        return ["m4a", "mp3"].lazy
            .map {
                return self.downloadsDirectory.appendingPathComponent(sanitizedFileName).appendingPathExtension($0)
            }
            .first { FileManager.default.fileExists(atPath: $0.path)
        }
    }
    
    func downloadFileExists(for url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        // Define characters that are illegal in file paths
        let illegalChars = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        
        // Split the string by illegal characters and rejoin them
        let components = fileName.components(separatedBy: illegalChars)
        
        // Join with an underscore or dash
        return components.joined(separator: "_")
    }
    

}
