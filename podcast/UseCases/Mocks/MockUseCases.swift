//
//  MockUseCases.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/8/26.
//

import Foundation

#if DEBUG

extension ManageSettingsUseCase {
    static var preview: ManageSettingsUseCase {
        ManageSettingsUseCase(repository: .preview)
    }
}

extension LoadEpisodeUseCase {
    static var preview: LoadEpisodeUseCase {
        LoadEpisodeUseCase(
            episodeRepo: EpisodeRepository.preview,
            playbackUseCase: PlaybackUseCase.preview
        )
    }
}

extension RefreshLibraryUseCase {
    static var preview: RefreshLibraryUseCase {
        RefreshLibraryUseCase(
            syncUseCase: .preview,
            manageDownloadsUseCase: .preview,
            updateChaptersUseCase: .preview,
            repository: .preview
        )
    }
}

extension SyncPodcastUseCase {
    static var preview: SyncPodcastUseCase {
        SyncPodcastUseCase(
            feedService: PodcastFeedService(),
            imageService: ImageService(),
            repository: .preview
        )
    }
}

extension ManageDownloadsUseCase {
    static var preview: ManageDownloadsUseCase {
        ManageDownloadsUseCase(
            repository: EpisodeRepository.preview,
            downloadManager: DownloadManager()
        )
    }
}

extension UpdateChaptersUseCase {
    static var preview: UpdateChaptersUseCase {
        UpdateChaptersUseCase(
            repository: EpisodeRepository.preview,
        )
    }
}

extension PlaybackUseCase {
    static var preview: PlaybackUseCase {
        PlaybackUseCase(
            playbackManager: PlaybackManager(),
            episodeRepository: EpisodeRepository.preview,
            settingsRepository: .preview,
            podcastRepository: .preview
        )
    }
}

extension SetEpisodeAsListenedUseCase {
    static var preview: SetEpisodeAsListenedUseCase {
        SetEpisodeAsListenedUseCase(
            downloadManager: DownloadManager(),
            episodeRepository: EpisodeRepository.preview,
            bookmarkRepository: BookmarkRepository.preview,
            createBookmarkClipUseCase: CreateBookmarkClipUseCase.preview
        )
    }
}

extension ProcessManualDownloadUseCase {
    static var preview: ProcessManualDownloadUseCase {
        ProcessManualDownloadUseCase(
            downloadManager: DownloadManager(),
            episodeRepository: EpisodeRepository.preview
        )
    }
}

extension ManageBookmarksUseCase {
    static var preview: ManageBookmarksUseCase {
        ManageBookmarksUseCase(bookmarkRepository: BookmarkRepository.preview)
    }
}

extension CreateBookmarkClipUseCase {
    static var preview: CreateBookmarkClipUseCase {
        CreateBookmarkClipUseCase(
            bookmarkRepository: BookmarkRepository.preview,
            filePathService: FilePathService()
        )
    }
}


#endif
