//
//  DownloadStatusView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/15/25.
//

import SwiftUI

struct DownloadStatusView: View {
    let state: DownloadState
    
    var body: some View {
        switch state {
        case .downloaded:
            Image(systemName: "arrow.down.circle.fill")
        case .downloading:
            Image(systemName: "arrow.down.circle.dotted")
        case .notDownloaded:
            Image(systemName: "cloud.circle").opacity(0.5)
        case .failed:
            Image(systemName: "exclamationmark.triangle").opacity(0.5)
        }
    }
}

#Preview {
    DownloadStatusView(state: DownloadState.downloading)
}
