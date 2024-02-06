//
//  ProximiioOffline+Sync.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import Proximiio
import StorageDone

extension ProximiioOffline {
    func initSyncTimer() {
        let queue = DispatchQueue(label: "io.proximi.app.timer")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(Int(syncInterval)))
        timer!.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.sync()
            }
        }
        
        timer!.resume()
    }
    
    func sync() async -> Bool {
        return await withCheckedContinuation { continuation in
            let delta = self.getLastSync()
            NSLog("Proximi.io Offline API syncing... (\(delta)) online status: (\(self.isOnline))")
            
            if (!isOnline) {
                NSLog("Proximi.io Offline API skipping data flush, connection not available")
                continuation.resume(returning: false);
                return
            }
            
            do {
                try flush()
            } catch (let ex) {
                continuation.resume(returning: false);
                NSLog("Flush Error \(ex)")
            }
            
            auditClient.sync(delta: delta) { changes in
                if (changes > 0) {
                    self.touchLastSync()
                    if (Proximiio.sharedInstance().authenticated()) {
                        Proximiio.sharedInstance().sync { result in
                            if (result) {
                                NSLog("Proximi.io SDK sync success")
                                continuation.resume(returning: true);
                            }
                        }
                    } else {
                        NSLog("Skipping Proximi.io sync (not authorized)")
                        continuation.resume(returning: false);
                    }
                } else {
                    //NSLog("Proximi.io no new changes available")
                    continuation.resume(returning: true);
                }
            }
        }
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
        let timestamp = Int64(NSDate().timeIntervalSince1970)
        let syncStatus = SyncStatus(id: "sync", lastSync: timestamp)
        do {
            self.database ++= syncStatus
        } catch {
            NSLog("error while creating sync state entry")
        }
    }
    
    public func setSyncInterval(_ interval: Int64) {
        self.syncInterval = interval;
    }
}
