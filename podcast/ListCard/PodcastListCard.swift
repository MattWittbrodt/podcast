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
    var image: String?
    
    var body: some View {
        HStack {
            if let image = image,
               let imageUrl = URL(string: image) {
                AsyncImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .frame(width: 100, height: 100, alignment: .topLeading)
                            .cornerRadius(25)
                    } else if phase.error != nil {
                        Text("Failed to load image.")
                            .foregroundColor(.red)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                Image(systemName: "microphone")
            }
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(author)
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

#Preview {
    let dm = DataManager.preview
    let sample = dm.podcasts.first!
    
    PodcastListCard(title: sample.title,
                    author: sample.author,
                    image: sample.imageUrl)
}
