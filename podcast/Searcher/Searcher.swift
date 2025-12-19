//
//  AddPodcast.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/26/25.
//
import SwiftUI
import CoreData

struct SearcherView: View {
    @EnvironmentObject private var discoveryManager: DiscoveryManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var enteredText = ""
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
                        await discoveryManager.parseKnownPodcast(feedUrl: rssAdditionText)
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
                await discoveryManager.search(term: enteredText)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 2) // Adjust corner radius as needed
                .fill(.white) // Background color
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(themeManager.selectedTheme.primaryColor, lineWidth: 3) // Border
                )
        )
        .foregroundStyle(themeManager.selectedTheme.textInputColor)
        .padding(.leading, 30)
        .padding(.top, 15)
    }
    
    private var searchResultsList: some View {
        List(discoveryManager.searchResults) { searchResult in
            PodcastRow(searchResult: searchResult) {
                Task {
                    await handleItemSelection(searchResult)
                }
            }
            .background(themeManager.selectedTheme.secondoryColor)
            .foregroundStyle(themeManager.selectedTheme.primaryColor)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .sheet(item: $discoveryManager.selectedPodcast) { _ in
            PodcastDiscoverView()
                .environmentObject(discoveryManager)
        }
    }
    
    private func handleItemSelection(_ item: PodcastIndexInfo) async {
        // Perform your operation first
        await discoveryManager.parseKnownPodcast(feedUrl: item.rssUrl())
    }
    
}

// Extracted subview for better organization
struct PodcastRow: View {
    let searchResult: PodcastIndexInfo
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

//#Preview {
//    let dm = DataManager.preview
//    let discovery = DiscoveryManager(dataManager: dm)
//    SearcherView()
//        .environmentObject(discovery)
//        .environmentObject(ThemeManager())
//}
