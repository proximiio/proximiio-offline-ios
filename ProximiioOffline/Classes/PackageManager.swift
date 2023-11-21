//
//  PackageManager.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation
import StorageDone
import FlyingFox

class PackageManager {
    let database : StorageDoneDatabase
    var package : [String: Any] = [:]
    var packageJSON : Data = "{}".data(using: .utf8)!
    var campuses : [[String: Any]] = []
    var campusesJSON : Data = "[]".data(using: .utf8)!
    
    static let fields = [
        "applications",
        "campuses",
        "departments",
        "floors",
        "geofences",
        "inputs",
        "places",
        "privacy_zones"
    ]
    
    init(database: StorageDoneDatabase) {
        self.database = database
    }
    
    func build() throws {
        var package = [:] as [String: Any]
        
        PackageManager.fields.forEach { field in
            let filtered: [OfflineModel] = "type".equal(field)<-database
            let items = filtered.map({ try! $0.json() })
            package[field] = items

            if (field == "campuses") {
                self.campuses = items
                self.campusesJSON = try! JSONSerialization.data(withJSONObject: self.campuses, options: .withoutEscapingSlashes)
            }
        }
        
        self.package = package;
        self.packageJSON = try JSONSerialization.data(withJSONObject: self.package, options: .withoutEscapingSlashes)
    }
    
    func preload() throws {
        let filePath = "offline_data/core/package"
        
        guard let path = Bundle.main.resourceURL?.appendingPathComponent(filePath) else {
            throw ManagerError.fileMissing
        }
        
        guard let data = try? Data(contentsOf: path) else {
            NSLog("PackageManager data access error")
            NSLog("invalid file access: \(path)")
            throw ManagerError.invalidFileAccess
        }
        
        guard let package = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
            throw ManagerError.invalidJSON
        }
        
        PackageManager.fields.forEach { preloadField(package: package, field: $0) }
    }
    
    func preloadField(package: [String: Any], field: String) {
        var items = [] as [OfflineModel]
        if let data = package[field] as? [[String: Any]] {
            try? data.forEach { item in
                let json = try JSONSerialization.data(withJSONObject: item)
                let jsonString = String(decoding: json, as: UTF8.self)
                let id = item["id"] as! String
                let offline = OfflineModel(id: id, data: jsonString, type: field)
                items.append(offline)
            }
        }
        self.database ++= items
    }
}
