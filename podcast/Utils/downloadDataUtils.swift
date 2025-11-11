//
//  downloadDataUtils.swift
//  podcast
//
//  Created by Matt Wittbrodt on 8/5/25.
//

import Foundation
import AVKit

enum downloadDataResponse: Equatable {
    case success
    case failure(String)
}

struct DownloadedData {
    var path: URL
    var duration: Int16?
}

class downloadDataUtils {
    
    static func getSharedDownloadsDirectory() -> URL {
        let groupID = "group.mattwTest.podcast" // Must match your App Group
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
        return containerURL.appendingPathComponent("Downloads")
    }
    
    static func getPathToFile(id: String) -> URL {
        let destinationDirectory = self.getSharedDownloadsDirectory()
        let uniqueFileName = "\(id).mp3"
        return destinationDirectory.appendingPathComponent(uniqueFileName)
    }
    
    static func downloadEpisodetoFile(url: String, episodeId: String) async throws -> DownloadedData {
        
        // Create a unique filename with timestamp
        guard let url = URL(string: url) else {
            throw DownloadError.invalidURL(url)
        }
        
        var destinationUrl = downloadDataUtils.getPathToFile(id: episodeId)
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            return DownloadedData(path: destinationUrl)
        }
        
        do {
            // Download the file
            print("Downloading at \(destinationUrl)")
            let (tempLocalUrl, response) = try await URLSession.shared.download(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw DownloadError.invalidResponse
            }
            
            // Move the file from temp location to destination
            try FileManager.default.moveItem(at: tempLocalUrl, to: destinationUrl)
            // Creating a player item to get the actual duration
            
            // Exclude from iCloud backup
            var resourceValue = URLResourceValues()
            resourceValue.isExcludedFromBackup = true
            try destinationUrl.setResourceValues(resourceValue)
            
            let asset = AVURLAsset(url: destinationUrl)
            let duration = try! await Int16(CMTimeGetSeconds(asset.load(.duration)))
            return DownloadedData(path: destinationUrl, duration: duration)
        } catch {
            // Handle specific errors or rethrow
            if let downloadError = error as? URLError {
                throw DownloadError.downloadFailed(downloadError)
            } else if (error as? CocoaError)?.code == .fileWriteFileExists {
                return DownloadedData(path: destinationUrl)
            } else {
                throw DownloadError.fileMoveFailed
            }
        }
    }
    
    static func deleteDownloadedFile(episodeId: String) async -> downloadDataResponse {
        do {
            let destinationUrl = downloadDataUtils.getPathToFile(id: episodeId)
            
            if !FileManager.default.fileExists(atPath: destinationUrl.path) {
                return .success
            }
            
            try await self.deleteFile(at: destinationUrl)
            return .success
        } catch {
            return .failure("\(error.localizedDescription)")
        }
    }

    // Finds all .mp3 files in Downloads directory
    static func findAllMP3sInDownloads() async -> [URL] {
        let sharedDownloads = self.getSharedDownloadsDirectory()
        
        do {
            let files = try await enumerateFiles(in: sharedDownloads)
            return files.filter { $0.isMP3 }
        } catch {
            print("Error finding MP3s: \(error)")
            return []
        }
    }

    // Deletes specified MP3 files
    static func deleteMp3Files() async -> (successCount: Int, failedURLs: [URL]) {
        let files = await self.findAllMP3sInDownloads()
        
        var successCount = 0
        var failedURLs: [URL] = []
        
        await withTaskGroup(of: (URL, Bool).self) { group in
            for file in files {
                group.addTask {
                    do {
                        try await self.deleteFile(at: file)
                        return (file, true)
                    } catch {
                        return (file, false)
                    }
                }
            }
            
            for await (file, success) in group {
                success ? (successCount += 1) : failedURLs.append(file)
            }
        }
        print("Deleted: \(successCount)")
        return (successCount, failedURLs)
    }
    
    // Function to set all downloads as 0 if all files have been removed
//    static func resetAllDownloads(context: NSManagedObjectContext) -> downloadDataResponse {
//        let episodes = 
//    }

    private static func enumerateFiles(in directory: URL) async throws -> [URL] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: [.contentTypeKey],
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                    )
                    continuation.resume(returning: files)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func deleteFile(at url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    try FileManager.default.removeItem(at: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension URL {
    var isMP3: Bool {
        // First try proper UTType checking
        if let type = try? resourceValues(forKeys: [.contentTypeKey]).contentType,
           type.conforms(to: .mp3) {
            return true
        }
        // Fallback to extension check
        return pathExtension.lowercased() == "mp3"
    }
}
