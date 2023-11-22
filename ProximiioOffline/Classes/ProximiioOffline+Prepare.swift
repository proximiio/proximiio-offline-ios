//
//  ProximiioOffline+Prepare.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation

extension ProximiioOffline {
    func checkAndPrepare() {
        createDirectory("visitors-buffer")
        createDirectory("events-buffer")
        createDirectory("positions-buffer")
        createDirectory("wayfinding_logs-buffer")
        createDirectory("search_logs-buffer")
    }
    
    
    func createDirectory(_ directory: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(directory)
        if (!FileManager.default.fileExists(atPath: url.path)) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
                NSLog("directory created \(url.absoluteString)")
            } catch {
                NSLog("filemanager error \(error)")
            }
        }
    }
}
