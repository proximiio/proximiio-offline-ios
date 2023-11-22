//
//  ProximiioOffline+Monitor.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation

extension ProximiioOffline {
    func initMonitor() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection is available.")
                self.isOnline = true
            } else {
                print("Internet connection is not available.")
                self.isOnline = false
            }
        }
        
        let networkQueue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: networkQueue)
    }
}
