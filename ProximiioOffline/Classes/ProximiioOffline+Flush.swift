//
//  ProximiioOffline+Flush.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import Alamofire
import Proximiio

extension ProximiioOffline {
    public func flush() throws {
        try flushResource(resource: "visitor", resource_url: "core/visitors")
        try flushBatchResource(resource: "event", resource_url: "core/events/batch")
        try flushBatchResource(resource: "position", resource_url: "core/positions/batch")
        try flushBatchResource(resource: "search_log", resource_url: "v5/geo/search_logs")
        try flushBatchResource(resource: "wayfinding_log", resource_url: "v5/geo/wayfinding_logs")
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
}
