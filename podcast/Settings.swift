//
//  Settings.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/15/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        VStack{
            Button(action: {deleteAllData()}) {
                Label("Delete All", systemImage: "trash")
            }
            Button(action: {
                Task{
                    await downloadDataUtils.deleteMp3Files()
                    
                    
                }
            }) {
                Label("Remove All Downloads", systemImage: "trash")
            }
        }
    }
    
    func deleteAllData() {
        
        // Fetch all episodes
        let episodeFetchRequest: NSFetchRequest<Episode> = Episode.fetchRequest()
        if let episodes = try? context.fetch(episodeFetchRequest) {
            for episode in episodes {
                context.delete(episode)
            }
        }
        
        // Fetch all podcasts
        let podcastFetchRequest: NSFetchRequest<Podcast> = Podcast.fetchRequest()
        if let podcasts = try? context.fetch(podcastFetchRequest) {
            for podcast in podcasts {
                context.delete(podcast)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving after delete: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
