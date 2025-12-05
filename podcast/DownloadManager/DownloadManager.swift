//
//  DownloadManager.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 11/15/25.
//

import Foundation
import Combine
import CoreData
import AVKit

class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    private let dataManager: DataManager
    
    // Must be a unique identifier for your app's downloads
    static let backgroundIdentifier = "com.planecast.Planecast"
    
    // The central hub for all state changes. It broadcasts a tuple: (Episode, new DownloadState)
    private let downloadStateSubject = PassthroughSubject<(NSManagedObjectID, DownloadState), Never>()
    private var currentStates: [NSManagedObjectID: DownloadState] = [:]
    
    // The Set acts as the real-time log of episode IDs currently being downloaded.
    @Published var activeDownloads: Set<NSManagedObjectID> = []
    
    private lazy var urlSession: URLSession = {
        // Use the BACKGROUND configuration for robust, out-of-app downloads
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundIdentifier)
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // Internal Mapping (needed for tracking task completion)
    private var taskMap: [Int: NSManagedObjectID] = [:]
    
    let downloadsDirectory: URL
    
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
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        // 1. Call the function/logic to get and create the directory
        guard let url = DownloadManager.setupDownloadsDirectory() else {
            // 2. Handle the fatal error if the directory setup is mandatory
            fatalError("FATAL ERROR: Could not set up application downloads directory.")
        }
        
        self.downloadsDirectory = url
        super.init()
    }
}

// MARK: - Public API
extension DownloadManager {
    
    func startDownload(for episode: Episode) {
        guard !downloadFileExists(for: episode), !activeDownloads.contains(episode.objectID)
        else {
            print("Download skipped: already downloaded or in progress.")
            return
        }
        
        guard let episodeUrl = URL(string: episode.enclosureUrl!) else {
            print("Bad enclosure URL or guid")
            return
        }
        
        let task = urlSession.downloadTask(with: episodeUrl)
        taskMap[task.taskIdentifier] = episode.objectID
        
        // Add episode ID to the active log and update the state subject
        self.update(episodeId: episode.objectID, newState: .downloading)
        DispatchQueue.main.async {
            self.activeDownloads.insert(episode.objectID)            
        }
        
        task.resume()
    }
    
    // function to track progress of specific episodes
    func downloadStatePublisher(for episodeId: NSManagedObjectID, initialDownloadState: Bool) -> AnyPublisher<DownloadState, Never> {
        //print("\(episodeId): Creating download state publisher...")
        // Start with the current state (if known), then listen to future changes
        let initialPublisher = Just(initialDownloadState ? DownloadState.downloaded : DownloadState.notDownloaded)
            .setFailureType(to: Never.self)
            .eraseToAnyPublisher()
        
        let futureChangesPublisher = downloadStateSubject
            // Only emit values for the episode we care about
            .filter { $0.0 == episodeId }
            // Map the tuple to just the DownloadState
            .map { $0.1 }
        
        // Combine the initial state and all future changes into one publisher
        return initialPublisher
            .merge(with: futureChangesPublisher)
            .eraseToAnyPublisher()
    }
    
    func downloadFileExists(for episode: Episode) -> Bool {
        guard let episodePath = self.generateStoreFilePath(for: episode) else {
            print("❌ No file path")
            return false
        }
        return FileManager.default.fileExists(atPath: episodePath.path)
    }
    
    func getFullDownloadPath(for episode: Episode) -> URL? {
        return self.generateStoreFilePath(for: episode)
    }
    
    func removeDownload(for episode: Episode) {
        guard let episodePath = self.generateStoreFilePath(for: episode) else {
            print("❌ No file path")
            return
        }
        do {
            if downloadFileExists(for: episode) {
                try FileManager.default.removeItem(at: episodePath)
            }
        } catch {
            print("❌ Download not removed")
        }
    }
}

// MARK: UrlSessionMethods
extension DownloadManager {
    
    // Called when the network transfer has finished and we need to handle result
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let episodeId = taskMap[downloadTask.taskIdentifier] else { return }
        let backgroundContext = dataManager.persistence.container.newBackgroundContext()
        
        var episode: Episode?
        backgroundContext.performAndWait {
            do {
                // Fetch the object using the thread-safe ID
                let backgroundEpisode = try backgroundContext.existingObject(with: episodeId)
                episode = backgroundEpisode as? Episode
            } catch {
                print("Error fetching episode in background: \(error)")
            }
        }
        guard let finalEpisode = episode else { print("no episode"); return }
        guard let destinationURL = generateStoreFilePath(for: finalEpisode) else { return }
        
        let fm = FileManager.default
        if fm.fileExists(atPath: destinationURL.path) {
            try? fm.removeItem(at: destinationURL)
        }

        do {
            try fm.moveItem(at: location, to: destinationURL)
            
            // 2. ✅ Calculate the actual duration of the downloaded file
            var finalDuration: Int16 = 0
            Task { @MainActor in
                let asset = AVURLAsset(url: destinationURL)
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)
                if durationSeconds.isFinite {
                    finalDuration = Int16(durationSeconds)
                }
                                
                backgroundContext.performAndWait {
                    do {
                        // Re-fetch the episode into the background context to ensure it's still valid
                        let episodeToUpdate = try backgroundContext.existingObject(with: episodeId) as! Episode
                        episodeToUpdate.duration = finalDuration
                        try backgroundContext.save()
                        
                        // Since this is Core Data, you should also notify the main context of changes
                        dataManager.saveMainContext()
                        
                    } catch {
                        print("Error updating and saving episode duration: \(error)")
                    }
                }
            }

            // 5. Dispatch UI/Combine updates to the Main Actor
            Task { @MainActor in
                self.activeDownloads.remove(episodeId)
                self.update(episodeId: episodeId, newState: DownloadState.downloaded)
                self.taskMap.removeValue(forKey: downloadTask.taskIdentifier)
            }
        } catch {
            print("Error during file finalization: \(error.localizedDescription)")
            
            Task { @MainActor in
                self.activeDownloads.remove(episodeId)
                self.update(episodeId: episodeId, newState: DownloadState.failed)
            }
        }
    }
    
    // If progress updates/logging is desired
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Optional: Log simple progress to console if needed, but DO NOT update published state
        // let currentProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        // if let episodeId = taskMap[downloadTask.taskIdentifier] {
        //     print("Progress for \(episodeId): \(String(format: "%.1f", currentProgress * 100))%")
        // }
    }
    
    // Called when task is finished with an error. Removes failed download from active download
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed: \(error.localizedDescription)")
            if let episodeId = taskMap[task.taskIdentifier] {
                // Clean up: remove episode ID from the active log
                DispatchQueue.main.async {
                    self.activeDownloads.remove(episodeId)
                    self.taskMap.removeValue(forKey: task.taskIdentifier)
                }
            }
        }
    }
    
    // CRITICAL for Background Sessions: Clean up the OS handler
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // This is where you would call the OS completion handler that was passed
        // to your App Delegate, confirming all background work is finished.
        print("DownloadManager: Background session finished all tasks for this batch.")
    }
}

// MARK: Internal API
extension DownloadManager {
    
    private func update(episodeId: NSManagedObjectID, newState: DownloadState) {
        // Only proceed if the state has genuinely changed
        guard currentStates[episodeId] != newState else { return }

        currentStates[episodeId] = newState
        downloadStateSubject.send((episodeId, newState))
    }
    
    func generateStoreFilePath(for episode: Episode) -> URL? {
        let fileName = "\(episode.savedFileName()).mp3"
        let sanitizedFileName = sanitizeFileName(fileName)
        return self.downloadsDirectory.appendingPathComponent(sanitizedFileName)
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

enum DownloadState {
    case notDownloaded, downloading, downloaded, failed
}
