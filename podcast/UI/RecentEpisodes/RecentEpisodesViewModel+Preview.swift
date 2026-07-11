//
//  RecentEpisodesViewModel+Preview.swift
//  podcast
//
//  Created by Matt Wittbrodt on 7/9/26.
//

import Foundation

#if DEBUG

extension RecentEpisodesViewModel {
    static var preview: RecentEpisodesViewModel {
        RecentEpisodesViewModel(
            refreshLibraryUseCase: .preview,
            processManualDownloadUseCase: .preview,
            setEpisodeAsListenedUseCase: .preview,
            playerViewModel: .preview,
            loadEpisodesUseCase: .preview,
            manageDownloadsUseCase: .preview
        )
    }
}
#endif
