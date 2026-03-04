//
//  NetworkMonitor.swift
//  podcast
//
//  Created by Matt Wittbrodt on 1/28/26.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // isExpensive = cellular
    @Published var isExpensive = false
    @Published var isConnected = true
    @Published var isCellular = false // Will look at the actual interface used

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                // isExpensive is true when on Cellular or Personal Hotspot
                self.isExpensive = path.isExpensive
                self.isConnected = path.status == .satisfied
                
                self.isCellular = path.usesInterfaceType(.cellular)
            }
        }
        
        monitor.start(queue: queue)
    }
}
