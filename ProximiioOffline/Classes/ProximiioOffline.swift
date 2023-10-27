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

public final class ProximiioOffline {
    let name = "ProximiioOffline"
    let server = HTTPServer(address: .loopback(port: 32080))
    var path = ""
    var token = ""
    public static let shared = ProximiioOffline()
    
    public func start() async throws {
        checkAndPrepare()
        
        if Bundle.main.url(forResource: path, withExtension: nil) != nil {
            let coreHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/core", serverPath: "core")
            await server.appendRoute("GET /core/*", to: coreHandler)
            
            let geoHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/v5", serverPath: "v5")
            await server.appendRoute("GET /v5/*", to: geoHandler)
        }

        await server.appendRoute("GET /v5/*", to: .directory(subPath: "\(path)/v5", serverPath: "v5"))
        await server.appendRoute("POST /core/visitors", to: VisitorHandler())
        await server.appendRoute("POST /core/events", to: EventHandler())
        await server.appendRoute("POST /core/events/batch", to: EventHandler())
        await server.appendRoute("POST /core/positions/batch", to: PositionHandler())
        await server.appendRoute("POST /v5/geo/wayfinding_logs", to: WayfindingLogHandler())
        await server.appendRoute("POST /v5/geo/search_logs", to: SearchLogHandler())
        
        try flush()
        NSLog("ProximiioOffline running")
        try await server.start()
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
    
    func flushResource(resource: String, resource_url: String) throws {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(resource)s-buffer")
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        var pack = [] as [[String: Any]]
        
        try items.forEach { item in
            let data = try Data(contentsOf: url.appendingPathComponent(item))
            let body = try JSONSerialization.data(withJSONObject: data)
            var request = URLRequest(url: try! "https://api.proximi.fi/\(resource_url)".asURL())
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            NSLog("url: \(request.url!)")
            NSLog("body: \(String.init(data: body, encoding: .utf8)!)")
            
            AF.request(request).responseData { response in
                switch response.result {
                case .success:
                    do {
                        let str = String(decoding: response.value ?? Data(), as: UTF8.self)
                        NSLog("response value \(str)")
                        do {
                            try FileManager.default.removeItem(atPath: url.appendingPathComponent(item).path)
                            NSLog("item removed: \(url.appendingPathComponent(item).path)")
                        } catch {
                            NSLog("file removal error: \(error)")
                        }
                    }
                case .failure(let error):
                    NSLog("error response: \(error)")
                }
            }
        }
        
        if (!pack.isEmpty) {
            
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
                NSLog("json item: \(item)")
                var i = item;
                i.updateValue(UUID().uuidString, forKey: "visitor_id")
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
            NSLog("url: \(request.url!)")
            NSLog("body: \(String.init(data: body, encoding: .utf8)!)")
            
            AF.request(request).responseData { response in
                switch response.result {
                case .success:
                    do {
                        let str = String(decoding: response.value ?? Data(), as: UTF8.self)
                        NSLog("response value \(str)")
                        let res = try JSONSerialization.jsonObject(with: response.value!)
                        items.forEach { item in
                            do {
                                try FileManager.default.removeItem(atPath: url.appendingPathComponent(item).path)
                                NSLog("item removed: \(url.appendingPathComponent(item).path)")
                            } catch {
                                NSLog("file removal error: \(error)")
                            }
                        }
                    } catch {
                        NSLog("parsing or removal error: \(error)")
                    }
                case .failure(let error):
                    NSLog("error response: \(error)")
                }
            }
        }
    }
}

