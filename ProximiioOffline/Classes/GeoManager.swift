//
//  GeoManager.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation
import StorageDone
import FlyingFox

let DummyFeatureCollection = "{\"type\":\"FeatureCollection\",\"features\":[]}"

class GeoManager {
    let database: StorageDoneDatabase
    var amenities: [[String: Any]] = []
    var amenitiesJSON: Data = "[]".data(using: .utf8)!
    var amenityCategories: [[String: Any]] = []
    var amenityCategoriesJSON: Data = "[]".data(using: .utf8)!
    var features: [String: Any] = ["type": "FeatureCollection", "features": []]
    var featuresJSON: Data = DummyFeatureCollection.data(using: .utf8)!
    var style: [String: Any] = [:]
    var styleJSON: Data = "{}".data(using: .utf8)!
    
    init(database: StorageDoneDatabase) {
        self.database = database
    }
    
    func build() throws {
        let filteredAmenities: [OfflineModel] = "type".equal("amenities")<-database
        let amenities = filteredAmenities.map({ try! $0.json() })
        self.amenities = amenities
        self.amenitiesJSON = try JSONSerialization.data(withJSONObject: self.amenities)
        
        let filteredAmenityCategories: [OfflineModel] = "type".equal("amenity_categories")<-database
        let amenityCategories = filteredAmenityCategories.map({ try! $0.json() })
        self.amenityCategories = amenityCategories
        self.amenityCategoriesJSON = try JSONSerialization.data(withJSONObject: self.amenityCategories)
        
        let filteredFeatures: [OfflineModel] = "type".equal("features")<-database
        let features = filteredFeatures.map({ try! $0.json() })
        self.features = ["type": "FeatureCollection", "features": features]
        self.featuresJSON = try JSONSerialization.data(withJSONObject: self.features)
        
        let filteredStyle: [OfflineModel] = "type".equal("styles")<-database
        let styles = filteredStyle.map({ try! $0.json() })
        
        if (styles.count > 0) {
            style = styles[0]
            var sources = style["sources"] as? [String: Any]
            var openmaptiles = sources?["openmaptiles"] as? [String: Any]
            if (openmaptiles != nil) {
                openmaptiles!["url"] = "http://localhost:32080/data/v3.json"
            }
            sources?["openmaptiles"] = openmaptiles
            style["sources"] = sources
            style["glyphs"] = "http://localhost:32080/fonts/{fontstack}/{range}.pbf"
            styleJSON = try JSONSerialization.data(withJSONObject: self.style, options: .withoutEscapingSlashes)
        }
    }
    
    func preload() throws {
        try preloadAmenities()
        try preloadFeatures()
        try preloadStyle()
    }
    
    func preloadAmenities() throws {
        let filePath = "offline_data/v5/geo/amenities"
        
        guard let path = Bundle.main.resourceURL?.appendingPathComponent(filePath) else {
            throw ManagerError.fileMissing
        }
        
        guard let data = try? Data(contentsOf: path) else {
            NSLog("invalid file access: \(path)")
            throw ManagerError.invalidFileAccess
        }
        
        guard let amenities = try? JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]] else {
            throw ManagerError.invalidJSON
        }
        
        var items = [] as [OfflineModel]
        
        try amenities.forEach({ item in
            let json = try JSONSerialization.data(withJSONObject: item)
            let jsonString = String(decoding: json, as: UTF8.self)
            let id = item["id"] as! String
            let offline = OfflineModel(id: id, data: jsonString, type: "amenities")
            items.append(offline)
        })
        
        self.database ++= items
    }
    
    func preloadAmenityCategories() throws {
        let filePath = "offline_data/v5/geo/amenity_categories"
        
        guard let path = Bundle.main.resourceURL?.appendingPathComponent(filePath) else {
            throw ManagerError.fileMissing
        }
        
        guard let data = try? Data(contentsOf: path) else {
            NSLog("invalid file access: \(path)")
            throw ManagerError.invalidFileAccess
        }
        
        guard let amenityCategories = try? JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]] else {
            throw ManagerError.invalidJSON
        }
        
        var items = [] as [OfflineModel]
        
        try amenityCategories.forEach({ item in
            let json = try JSONSerialization.data(withJSONObject: item)
            let jsonString = String(decoding: json, as: UTF8.self)
            let id = item["id"] as! String
            let offline = OfflineModel(id: id, data: jsonString, type: "amenity_categories")
            items.append(offline)
        })
        
        self.database ++= items
    }
    
    func preloadStyle() throws {
        let filePath = "offline_data/v5/geo/styles/default"
        
        guard let path = Bundle.main.resourceURL?.appendingPathComponent(filePath) else {
            throw ManagerError.fileMissing
        }
        
        guard let data = try? Data(contentsOf: path) else {
            NSLog("invalid file access: \(path)")
            throw ManagerError.invalidFileAccess
        }
        
        guard let styleData = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
            throw ManagerError.invalidJSON
        }
        
        let json = try JSONSerialization.data(withJSONObject: styleData)
        let jsonString = String(decoding: json, as: UTF8.self)
        let id = styleData["id"] as! String
        let offline = OfflineModel(id: id, data: jsonString, type: "styles")
        self.database ++= offline
    }
    
    func preloadFeatures() throws {
        let filePath = "offline_data/v5/geo/features"
        
        guard let path = Bundle.main.resourceURL?.appendingPathComponent(filePath) else {
            throw ManagerError.fileMissing
        }
        
        guard let data = try? Data(contentsOf: path) else {
            NSLog("invalid file access: \(path)")
            throw ManagerError.invalidFileAccess
        }
        
        guard let collection = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
            throw ManagerError.invalidJSON
        }

        let collectionFeatures = collection["features"] as? [[String: Any]]
        var items = [] as [OfflineModel]
        
        try collectionFeatures?.forEach({ item in
            let json = try JSONSerialization.data(withJSONObject: item)
            let jsonString = String(decoding: json, as: UTF8.self)
            let id = (item["id"] as! String)
            let offline = OfflineModel(id: id, data: jsonString, type: "features")
            self.database ++= offline
        })
    }
}
