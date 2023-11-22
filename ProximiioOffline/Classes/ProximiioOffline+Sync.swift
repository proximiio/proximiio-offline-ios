//
//  ProximiioOffline+Sync.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import Proximiio

extension ProximiioOffline {
    func initSyncTimer() {
        let queue = DispatchQueue(label: "io.proximi.app.timer")  // you can also use `DispatchQueue.main`, if you want
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(Int(syncInterval)))
        timer!.setEventHandler { [weak self] in
            NSLog("Proximi.io Offline API syncing... (\(self!.getLastSync()))")
            
            if (self != nil && !self!.isOnline) {
                NSLog("Proximi.io Offline API skipping data flush, connection not available")
                return
            }
            
            guard let offline = self else {
                NSLog("Proximi.io Offline API instance not available, skipping sync")
                return
            }
            
            do {
                try offline.flush()
            } catch (let ex) {
                NSLog("Flush Error \(ex)")
            }
            
            offline.auditClient.sync(delta: offline.getLastSync()) { changes in
                if (changes > 0) {
                    offline.touchLastSync()
                    DispatchQueue.main.async {
                        if (Proximiio.sharedInstance().authenticated()) {
                            Proximiio.sharedInstance().sync { result in
                                if (result) {
                                    NSLog("Proximi.io SDK sync success")
                                }
                            }
                        } else {
                            NSLog("Skipping Proximi.io sync (not authorized)")
                        }
                    }
                }
            }
        }
        
        timer!.resume()
    }
    
    func getLastSync() -> Int64 {
        guard let syncs: [SyncStatus] = try? database.get() else {
            return 0 as Int64
        }
        
        if (syncs.count == 1) {
            let sync = syncs[0];
            return sync.lastSync
        }
        
        return 0 as Int64
    }
    
    func touchLastSync() {
        let timestamp = Int64(NSDate().timeIntervalSince1970);
        let syncStatus = SyncStatus(id: "sync", lastSync: timestamp)
        do {
            try database.insertOrUpdate(element: syncStatus)
        } catch {
            NSLog("error while creating sync state entry")
        }
    }
    
    public func setSyncInterval(_ interval: Int64) {
        self.syncInterval = interval;
    }
}
