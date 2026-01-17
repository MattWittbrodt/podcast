//
//  ChapterList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/10/25.
//

import SwiftUI

struct PlayerChapters: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSheet = false
    
    var body: some View {
        if let chapters = playbackManager.episodeChapters,
                   let chapter = playbackManager.currentChapter {
            HStack{
                Image(systemName: "list.dash")
                Text("\(chapter.title ?? "Missing title")")
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
            }
            .onTapGesture { showSheet = true }
            .sheet(isPresented: $showSheet) {
                ChapterListView(
                    chapters: chapters,
                    currentChapterStartTime: chapter.startTime,
                    onChapterSelected: { time in
                        playbackManager.seek(seconds: Int64(time))
                    }
                )
                .environmentObject(themeManager)
            }
        }
    }
}

struct ChapterListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let chapters: [Chapter]
    let currentChapterStartTime: Int16
    let onChapterSelected: (Double) -> Void
    
    init(chapters: [Chapter],
         currentChapterStartTime: Int16,
         onChapterSelected: @escaping (Double) -> Void) {
        self.chapters = chapters
        self.currentChapterStartTime = currentChapterStartTime
        self.onChapterSelected = onChapterSelected
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            chapterScrollView(with: proxy)
                .onAppear { scrollToCurrentChapter(using: proxy) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func chapterScrollView(with proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(chapters, id: \.startTime) { chapter in
                    chapterButton(for: chapter)
                        .id(chapter.startTime)
                }
            }
            .background(Color(themeManager.selectedTheme.secondoryColor).opacity(0.85))
            .padding(.vertical)
        }
    }
    
    private func chapterButton(for chapter: Chapter) -> some View {
        Button {
            onChapterSelected(Double(chapter.startTime))
        } label: {
            ChapterRow(
                chapter: chapter,
                isCurrent: chapter.startTime == currentChapterStartTime
            )
            .environmentObject(themeManager)
        }
        .buttonStyle(.plain) // Add if you want to remove default button styling
    }
    
    private func scrollToCurrentChapter(using proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut) {
                proxy.scrollTo(currentChapterStartTime, anchor: .center)
            }
        }
    }
}

struct ChapterRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let chapter: Chapter
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            Text(chapter.title ?? "")
                .fontWeight(isCurrent ? .bold : .thin)
                .foregroundColor(isCurrent ? Color(themeManager.selectedTheme.primaryColor) : Color(themeManager.selectedTheme.primaryColor))
            Spacer()
            Text(formattedTime(time: Double(chapter.startTime)))
                .foregroundColor(Color(themeManager.selectedTheme.primaryColor))
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            isCurrent ? Color(themeManager.selectedTheme.primaryColor).opacity(0.10) : Color.clear
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

//#Preview {
//    ChapterList()
//}
