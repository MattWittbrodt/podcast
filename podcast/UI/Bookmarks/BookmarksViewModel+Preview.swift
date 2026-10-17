//
//  BookmarksViewModel+Preview.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/13/26.
//

import Foundation

#if DEBUG

extension BookmarksViewModel {
    static var preview: BookmarksViewModel {
        let vm = BookmarksViewModel(
            manageBookmarksUseCase: ManageBookmarksUseCase.preview,
            bookmarkPlaybackManager: BookmarkPlaybackManager(playbackManager: PlaybackManager())
        )
        let context = PersistenceController.preview.container.viewContext
        let objects = Array(context.registeredObjects)
        
        guard objects.count >= 2 else { return vm }
        
        vm.bookmarks = [
            BookmarkRecord(
                objectId: objects[0].objectID,
                savedDate: Date().addingTimeInterval(-86400),
                customLabel: "Custom Label for this Great Episode",
                audioFilePath: Bundle.main.bundleURL,
                isAudioFromEpisode: true,
                startTime: 320,
                episodeId: PersistenceController.preview.container.viewContext.registeredObjects.first!.objectID,
                episodeTitle: "Another Great Episode",
                podcastTitle: "Tech Talks",
                publishedDate: Date().addingTimeInterval(-86400)
            ),
            BookmarkRecord(
                objectId: objects[1].objectID,
                savedDate: Date().addingTimeInterval(-3600),
                customLabel: "Custom label for the Future of AI",
                audioFilePath: Bundle.main.bundleURL,
                isAudioFromEpisode: true,
                startTime: 450,
                episodeId: PersistenceController.preview.container.viewContext.registeredObjects.first!.objectID,
                episodeTitle: "The Future of AI",
                podcastTitle: "Hard Fork",
                publishedDate: Date()
            )
        ]
        return vm
    }
}
#endif
