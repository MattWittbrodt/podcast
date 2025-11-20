//
//  UnlistenedEpisodesList.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/16/25.
//

import Foundation
import Combine

class UnlistenedEpisodeList: ObservableObject {
    // 💡 This is the only thing that will trigger the List's body to rebuild
    @Published var episodes: [Episode] = []

    // Inject the DataManager to fetch the list initially or refresh it
    private let dataManager: DataManager
    
    // You might need a way to listen to global DataManager changes
    // and refresh this list if the list source depends on it.
    private var cancellables = Set<AnyCancellable>()

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.episodes = dataManager.unlistenedEpisodes // Assuming this is an array property
        
        // Setup subscription to dataManager changes if necessary
        dataManager.objectWillChange
            .sink { [weak self] _ in
                // When DataManager changes (e.g., episode marked listened), refresh this list
                "💡🔄 Should refresh"
                self?.refreshList()
            }
            .store(in: &cancellables)
    }
    
    func refreshList() {
        // Run Core Data fetch logic here, or just update from the DataManager's internal array
        print("🔄 Refreshing list")
        DispatchQueue.main.async { // Ensure @Published update is on main thread
            do {
                self.episodes = try self.dataManager.loadunlistenedEpisodes()
            } catch {
                print("Failed to get episodes")
            }
        }
    }
}
