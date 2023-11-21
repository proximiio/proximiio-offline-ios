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
    var syncInterval: Int64 = 20
    var timer: DispatchSourceTimer?
    var isOnline = false
    
    init() {
        self.geoManager = GeoManager(database: database)
        self.packageManager = PackageManager(database: database)
        self.auditClient = AuditClient(database: database)
    }
    
    public func start(_ token: String) async throws {
        self.token = token;
        checkAndPrepare()
        
        // Dispose of collected data
        try flush()
        
        if (getLastSync() == 0) {
            // Spawn database records from included files
            try packageManager.preload()
            try geoManager.preload()
        }

        // Prepare JSON cache
        try packageManager.build()
        try geoManager.build()
        
        // HTTP Routes
        if Bundle.main.url(forResource: path, withExtension: nil) != nil {
            let fontHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/fonts", serverPath: "fonts")
            await server.appendRoute("GET /fonts/*", to: fontHandler)
            
            let dataHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/data", serverPath: "data")
            await server.appendRoute("GET /data/*", to: dataHandler)
        }
        
        await server.appendRoute("GET /core/current_user", to: .file(named: "\(path)/core/current_user"))
        await server.appendRoute("GET /core/package", to: PackageHandler())
        await server.appendRoute("GET /core/cagmpuses", to: CampusesHandler())
        await server.appendRoute("GET /v5/geo/amenities", to: AmenitiesHandler())
        await server.appendRoute("GET /v5/geo/amenity_categories", to: AmenityCategoriesHandler())
        await server.appendRoute("GET /v5/geo/features", to: FeaturesHandler())
        await server.appendRoute("GET /v5/geo/styles/default", to: StyleHandler())
        
        await server.appendRoute("POST /core/visitors", to: VisitorHandler())
        await server.appendRoute("POST /core/events", to: EventHandler())
        await server.appendRoute("POST /core/events/batch", to: EventHandler())
        await server.appendRoute("POST /core/positions/batch", to: PositionHandler())
        await server.appendRoute("POST /v5/geo/wayfinding_logs", to: WayfindingLogHandler())
        await server.appendRoute("POST /v5/geo/search_logs", to: SearchLogHandler())
        
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
        
        timer!.resume()
        
        Task {
            try await server.start()
        }
        
        try await server.waitUntilListening()
        let address = await getAddress();
        (ProximiioAPI.sharedManager())?.setApi(address)
        (ProximiioAPI.sharedManager())?.setApiVersion("v5")
        
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
        NSLog("Proximi.io Offline API Running")
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
    
    public func getPackage() -> Data {
        return self.packageManager.packageJSON
    }
    
    public func getCampuses() -> Data {
        return self.packageManager.campusesJSON
    }
    
    public func getAmenities() -> Data {
        return self.geoManager.amenitiesJSON
    }
    
    public func getAmenityCategories() -> Data {
        return self.geoManager.amenityCategoriesJSON
    }
    
    public func getFeatures() -> Data {
        return self.geoManager.featuresJSON
    }
    
    public func getStyle() -> Data {
        return self.geoManager.styleJSON
    }
    
    public func flush() throws {
        try flushResource(resource: "visitor", resource_url: "core/visitors")
        try flushBatchResource(resource: "event", resource_url: "core/events/batch")
        try flushBatchResource(resource: "position", resource_url: "core/positions/batch")
        try flushBatchResource(resource: "search_log", resource_url: "v5/geo/search_logs")
        try flushBatchResource(resource: "wayfinding_log", resource_url: "v5/geo/wayfinding_logs")
    }

    func checkAndPrepare() {
        createDirectory("visitors-buffer")
        createDirectory("events-buffer")
        createDirectory("positions-buffer")
        createDirectory("wayfinding_logs-buffer")
        createDirectory("search_logs-buffer")
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
    
    public func setPath(_ path: String) {
        self.path = path
    }
    
    public func setToken(_ token: String) {
        self.token = token;
    }
    
    public func setApi(_ api: String) {
        self.api = api;
    }
    
    public func setSyncInterval(_ interval: Int64) {
        self.syncInterval = interval;
    }
    
    func flushResource(resource: String, resource_url: String) throws {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(resource)s-buffer")
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        try items.forEach { item in
            let itemPath = url.appendingPathComponent(item)
            let data = try Data(contentsOf: url.appendingPathComponent(item))

            var request = URLRequest(url: try! "https://api.proximi.fi/\(resource_url)".asURL())
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            AF.request(request).responseData { response in
                switch response.result {
                case .success:
                    do {
                        try FileManager.default.removeItem(at: itemPath)
                    } catch {
                        NSLog("file removal error: \(error)")
                    }
                case .failure(let error):
                    NSLog("error response: \(error)")
                }
            }
        }
    }
    
    func flushBatchResource(resource: String, resource_url: String) throws {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(resource)s-buffer")
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        var pack = [] as [[String: Any]]
        
        try items.forEach { item in
            let data = try Data(contentsOf: url.appendingPathComponent(item))
            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            json?.forEach({ item in
                var i = item;
                i.updateValue(Proximiio.sharedInstance().visitorId, forKey: "visitor_id")
                pack.append(i)
            })
        }
        
        if (!pack.isEmpty) {
            let body = try JSONSerialization.data(withJSONObject: pack)
            var request = URLRequest(url: try! "https://api.proximi.fi/\(resource_url)".asURL())
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            AF.request(request).responseData { response in
                switch response.result {
                case .success:
                    items.forEach { item in
                        do {
                            try FileManager.default.removeItem(atPath: url.appendingPathComponent(item).path)
                        } catch {
                            NSLog("file removal error: \(error)")
                        }
                    }
                case .failure(let error):
                    NSLog("error response: \(error)")
                }
            }
        }
    }
    
    deinit {
        timer = nil
    }
}

