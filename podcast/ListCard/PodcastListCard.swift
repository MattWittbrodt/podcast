//
//  PodcastListView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 3/23/25.
//

import SwiftUI

struct PodcastListCard: View {
    
    var title: String
    var author: String
    var image: String
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: image)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .frame(width: 100, height: 100, alignment: .topLeading)
                        .cornerRadius(25)
                } else if phase.error != nil {
                    Text("Failed to load image.") // Indicates that the image failed to load.
                        .foregroundColor(.red)
                } else {
                    ProgressView()
                }
            }
            VStack {
                Text(title)
                    .font(.headline)
                Text(author)
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

//#Preview {
//    PodcastListCard(title: Podcast.example.title,
//                    author: Podcast.example.author,
//                    image: Podcast.example.image)
//}
