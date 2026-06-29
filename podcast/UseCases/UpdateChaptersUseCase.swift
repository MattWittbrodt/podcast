//
//  UpdateChaptersUseCase.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 5/9/26.
//

import CoreData

struct UpdateChaptersUseCase {
    let repository: EpisodeRepository
    let feedService = PodcastFeedService()
    let imageService = ImageService()

    func execute() async {
        // 1. Get the IDs of episodes that need chapters (MainActor/Repository)
        let episodeIDs = await MainActor.run {
            (try? repository.getUnlistenedEpisodesWithChapters())?.map { $0.objectID } ?? []
        }

        // 2. Process each episode
        // We can use a TaskGroup here too if you want it to be fast!
        await withTaskGroup(of: Void.self) { group in
            for id in episodeIDs {
                group.addTask {
                    await self.syncChapters(for: id)
                }
            }
        }
    }

    private func syncChapters(for id: NSManagedObjectID) async {
        
        // 1. Fetch the data from the MainActor (The "Top Slice")
        let urlString = await MainActor.run { () -> String? in
            repository.getEpisode(for: id)?.chaptersUrl
        }
        
        do {
            // 2. Perform validation back on the background thread
            guard let urlString else { return }
            
            guard let decoded = try await feedService.fetchNewChapters(for: urlString) else {
                return
            }
            
            // 3. Fetch Images for those chapters (Background)
            // We do this BEFORE we touch the database
            let chaptersWithImageData = await withTaskGroup(of: ChapterInfo.self) { group in
                for chapter in decoded.chapters {
                    group.addTask {
                        var newChapWithData = chapter
                        if let url = chapter.img {
                            let data = await imageService.getImageData(from: url)
                            newChapWithData.imgData = data
                        }
                        return newChapWithData
                    }
                }
                var collectedChapters = [ChapterInfo]()
                
                for await finishedChapter in group {
                    collectedChapters.append(finishedChapter)
                }
                return collectedChapters
            }            
            try await repository.updateChapters(for: id, with: chaptersWithImageData)
        } catch {
            print("Failed processing chapters for \(urlString ?? "unknown"): \(error)")
        }
    }
}
