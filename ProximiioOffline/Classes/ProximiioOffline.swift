//
//  ProximiioOffline.swift
//  ProximiioOffline_Example
//
//  Created by Matej Drzik on 26/10/2023.
//  Copyright © 2023 Proximi.io. All rights reserved.
//

import Alamofire
import Foundation
import FlyingFox
import FlyingSocks
import StorageDone
import Proximiio
import Network

@MainActor
public final class ProximiioOffline {
    public static let shared = ProximiioOffline()
    let name = "ProximiioOffline"
    let monitor = NWPathMonitor()
    let server = HTTPServer(address: .loopback(port: 32080))
    let database = StorageDoneDatabase(name: "proximiio_offline_models")
    let packageManager: PackageManager
    let geoManager: GeoManager
    let auditClient: AuditClient
    var api = "https://api.proximi.fi"
    var path = "offline_data"
    var token = ""
    var syncInterval: Int64 = 180
    var timer: DispatchSourceTimer?
    var isOnline = false
    var serverTask: Task<(), Error> = Task {}
    
    init() {
        self.geoManager = GeoManager(database: database)
        self.packageManager = PackageManager(database: database)
        self.auditClient = AuditClient(database: database)
        self.initMonitor()
    }
    
    public func resetAll() {
        let syncStatus = SyncStatus(id: "sync", lastSync: 0)
        do {
            try self.database.deleteAllAndInsert(element: OfflineModel(id: "dummy", data: "{}", type: "dummy"))
            NSLog("database reset successful")
        } catch {
            NSLog("database reset unsuccessful")
        }
    }

    
    public func start(_ token: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            self.token = token
            do {
                // Prepare directory structure
                checkAndPrepare()
                
                // Dispose of collected data
                try flush()
                
                if (getLastSync() == 0) {
                    // Spawn database records from included files on first run
                    try packageManager.preload()
                    try geoManager.preload()
                }
                
                // Prepare JSON cache
                try packageManager.build()
                try geoManager.build()
                
                let task = Task {
                    await add_routes(server)
                    self.serverTask = Task {
                        try await server.start()
                    }
                    try await server.waitUntilListening()
                    let address = await self.getAddress()
                    // await self.sync()
                    let result = await self.initProximiio(address)
                    initSyncTimer()
                    continuation.resume(returning: true)
                }
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
    
    func socketToString(addr: Socket.Address?) -> String {
        switch addr {
         case let .ip4(_, port: port):
            return "http://localhost:\(port)"
         case let .ip6(_, port: port):
            return "http://localhost:\(port)"
         default:
            return ""
         }
    }
    
    public func getAddress() async -> String {
        guard let address = await server.listeningAddress else {
            return "http://localhost:30080"
        }
        
        return socketToString(addr: address)
    }
    
    public func setPath(_ path: String) {
        self.path = path
    }
    
    public func setToken(_ token: String) {
        self.token = token;
    }
    
    public func setApi(_ api: String) {
        self.api = api;
    }
    
    deinit {
        timer = nil
    }
}

