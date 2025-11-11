//
//  AddPodcast.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/26/25.
//
import SwiftUI
import CoreData

struct Searcher: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject var viewModel = PodcastSearchViewModel()
    
    @State private var enteredText = ""
    @State private var selectedItem: PodcastInfo?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var showTextField = false
    @State private var rssAdditionText = ""
        
    var body: some View {
        content
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .background(themeManager.selectedTheme.secondoryColor)
    }
    
    private var content: some View {
        
        ZStack {
            VStack {
                HStack{
                    Text("Search Podcasts")
                        .font(.title)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.leading, 20)
                HStack {
                    searchField
                    rssButton
                }
                searchResultsList
            }
            
            if showTextField {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showTextField = false
                        }
                    }
                    .zIndex(1) // Below text field but above main content
                    .transition(.opacity)
                rssSearchBar
            }
        }
    }

    private var rssButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showTextField.toggle()
            }
        } label: {
            Image(systemName: "waveform.path.badge.plus")
                .font(.title2)
                .foregroundColor(themeManager.selectedTheme.primaryColor)
        }
        .padding(.trailing, 30)
        .padding(.top, 15)
        .padding(.leading, 10)
    }
    
    private var rssSearchBar: some View {
        VStack {
            TextField("Enter RSS feed link", text: $rssAdditionText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .foregroundStyle(themeManager.selectedTheme.primaryColor)
            
            Button("Search") {
                withAnimation {
                    Task {
                        do {
                            let podcastInfo = try await PodcastInfo.from_rss(url: rssAdditionText)
                            selectedItem = podcastInfo
                        } catch {
                            alertMessage = "\(error)"
                            showAlert = true
                        }
                    }
                    showTextField = false
                }
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(themeManager.selectedTheme.secondoryColor)
            .tint(themeManager.selectedTheme.primaryColor)
        }
        .padding()
        .background(.thickMaterial)
        .cornerRadius(10)
        .shadow(radius: 10)
        .frame(width: 300)
        .transition(.scale.combined(with: .opacity))
        .zIndex(2) // Highest z-index
        .offset(y: -100) // Position above button
    }
    
    private var searchField: some View {
        TextField(text: $enteredText) {
            Text("Search for Podcasts")
                .foregroundColor(themeManager.selectedTheme.textInputColor.opacity(0.4))
        }
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .onChange(of: enteredText) {
            Task {
                await viewModel.searchPodcasts(searchTerm: enteredText)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 3) // Adjust corner radius as needed
                .fill(.white) // Background color
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(themeManager.selectedTheme.primaryColor, lineWidth: 3) // Border
                )
        )
        .foregroundStyle(themeManager.selectedTheme.textInputColor)
        .padding(.leading, 30)
        .padding(.top, 15)
    }
    
    private var searchResultsList: some View {
        NavigationStack {
            List(viewModel.searchResults) { searchResult in
                PodcastRow(searchResult: searchResult) {
                    selectedItem = searchResult
                }
                .background(themeManager.selectedTheme.secondoryColor)
                .foregroundStyle(themeManager.selectedTheme.primaryColor)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
            .background(themeManager.selectedTheme.secondoryColor)
        }
        .listStyle(.plain)
        .sheet(item: $selectedItem) { item in
            PodcastIntro(podcast: item)
                .environment(\.managedObjectContext, context)
        }
    }
}

// Extracted subview for better organization
struct PodcastRow: View {
    let searchResult: PodcastInfo
    let action: () -> Void
    
    var body: some View {
        NavigationLink(value: searchResult) {
            PodcastListCard(
                title: searchResult.title,
                author: searchResult.author,
                image: searchResult.image
            )
        }
        .onTapGesture(perform: action)
    }
}

//struct TextEntryView_Previews: PreviewProvider {
//    static var previews: some View {
//        Searcher()
//            .environment(\.managedObjectContext, PersistenceManager().preview.container.viewContext)
//            .environmentObject(ThemeManager())
//    }
//}
