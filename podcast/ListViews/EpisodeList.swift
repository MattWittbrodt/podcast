//
//  EpisodeList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/23/25.
//

import SwiftUI
import CoreData

struct LongTapMenuView: View {
    let podcast: Podcast
    
    var body : some View {
        Menu {
            Button(role: .destructive) {
                Podcast.delete(podcast: podcast)
            } label: {
                Label("Unsubscribe", systemImage: "bookmark.slash")
            }
            Button() {
                Task {
                    await Podcast.setAllListened(podcast: podcast)
                }
            } label: {
                Label("Mark all as listened", systemImage: "tray.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .padding(8)
        }.padding(2)
    }
}

struct HeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let podcast: Podcast
    
    var body: some View {
        HStack {
            Spacer(minLength: 90)
            Text(podcast.title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(themeManager.selectedTheme.primaryColor)
                .frame(maxWidth: .infinity)
            LongTapMenuView(podcast: podcast)
                .padding(.trailing)
        }
        .frame(height: 44)
    }
}

struct ListCardView<ViewModel: PlayerViewModelProtocol>: View {
    @EnvironmentObject var playerManager: ViewModel
    let episode: Episode
    
    var body: some View {
        
        EpisodeListCard(episode: episode)
        .onTapGesture {
            Task{
                await playerManager.setupPlayer(episode: episode)
            }
            playerManager.showFullPlayer = true
        }
        .contextMenu {
            Button(action: {episode.lastListened = 0})
               {
                    Label("Mark as unlistened", systemImage: "tray.and.arrow.up.fill")
                }
            Button(action: {
                Task {
                    try? await downloadDataUtils.downloadEpisodetoFile(url: episode.enclosureUrl!, episodeId: episode.downloadId)
                }}) {
                    Label("Download", systemImage: "square.and.arrow.down.fill")
                }
        }
    }
}

struct EpisodeList<ViewModel: PlayerViewModelProtocol>: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var playerManager: ViewModel
    @ObservedObject var podcast: Podcast
    @State private var selectedEpisode: Episode?
    var episodeList: [Episode]
    
    var body: some View {
        Color(themeManager.selectedTheme.secondoryColor)
            .ignoresSafeArea(.all)
            .overlay(
        
            GeometryReader { geometry in
                VStack {
                    HeaderView(podcast: podcast)
                    ScrollView {
                        LazyVStack {
                            let _ = print("\(self.episodeList.count) - \(self.podcast.title)")
                            ForEach(self.episodeList, id: \.objectID) { episode in
                                ListCardView<ViewModel>(episode: episode)
                                    .environmentObject(playerManager)
                                    .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height - 50)
                    }
                }
            }
        )
    }
}

//#Preview {
//    
//    let previewContainer = PersistenceController.preview.container
//    
//    // Create a test podcast if fetch fails
//    let podcast: Podcast = {
//        let fetchRequest = Podcast.queryByFeedId(41504)
//        fetchRequest.fetchLimit = 1
//        
//        do {
//            let results = try PersistenceController.preview.container.viewContext.fetch(fetchRequest)
//            if let foundPodcast = results.first {
//                return foundPodcast
//            }
//        } catch {
//            print("Error fetching podcast: \(error)")
//        }
//        
//        // Fallback to example podcast
//        let example = Podcast.example
//        return example
//    }()
//    EpisodeList<MockPlayerViewModel>(podcast: podcast)
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//        .environmentObject(MockPlayerViewModel(context: previewContainer.viewContext))
//        .environmentObject(ThemeManager())
//}
