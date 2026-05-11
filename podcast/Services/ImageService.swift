//
//  ImageService.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import Foundation

struct ImageService {
    
    private func loadImageFromWeb(url: String) async throws -> Data? {
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
        
    func getImageData(from url: String) async -> Data? {
        guard let imgData = try? await self.loadImageFromWeb(url: url) else {
            return nil
        }
        return imgData
    }
    
    func enrichEpisodesWithImages(for rawEpisodes: [RSSEpisode]) async -> [RSSEpisode] {
        return await withTaskGroup(of: RSSEpisode.self, returning: [RSSEpisode].self) { group in
            for episode in rawEpisodes {
                group.addTask {
                    var updateEpisode = episode
                    guard let imgData = try? await self.loadImageFromWeb(url: episode.imageUrl) else {
                        return episode
                    }
                    updateEpisode.imageData = imgData
                    return updateEpisode
                }
            }
            
            var processedEpisodes = [RSSEpisode]()
            for await result in group {
                let r = result
                processedEpisodes.append(r)
            }
            return processedEpisodes
        }
    }
    
}
