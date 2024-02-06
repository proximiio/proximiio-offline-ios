//
//  AuditClient.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 06/11/2023.
//

import Foundation
import Alamofire
import StorageDone
import CrystDBCipher
import Proximiio

class AuditClient {
    let database: StorageDoneDatabase
    
    init(database: StorageDoneDatabase) {
        self.database = database
    }
    
    func getType(_ entity: String) -> String {
        switch entity {
        case "Amenity":
            "amenities"
        case "AmenityCategory":
            "amenity_categories"
        case "Application":
            "applications"
        case "Campus":
            "campuses"
        case "Department":
            "departments"
        case "Feature":
            "features"
        case "Floor":
            "floors"
        case "Geofence":
            "geofences"
        case "Inputs":
            "inputs"
        case "Place":
            "places"
        case "PrivacyZone":
            "privacy_zones"
        default:
            "unknown"
        }
    }

    func syncItem(_ action: String, _ entity: String, _ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let serialized = String(decoding: jsonData, as: UTF8.self)
            let id = data["id"] as! String
            let model = OfflineModel(id: id, data: serialized, type: self.getType(entity))
            
            if (action == "delete") {
                try database.delete(element: model)
                if (entity == "Feature") {
                    ProximiioGeoJSON.cs_deleteFromDB(withCondition: "identifier == '\(id)'")
                }
            } else {
                try database.upsert(element: model)
            }
        } catch {
            NSLog("Serialization error: \(action), \(entity), \(data)")
        }
    }
    
    @MainActor public func sync(delta: Int64, onComplete: @escaping (Int) -> Void) {
        let request = AF.request("https://api.proximi.fi/v5/audit/changes?delta=\(delta * 1000)", headers: [
            "Authorization": "Bearer \(ProximiioOffline.shared.token)"
        ])
        
        request.responseData { response in
            switch response.result {
            case .success:
                do {
                    guard let items = try JSONSerialization.jsonObject(with: response.value!) as? [[String: Any]] else {
                        NSLog("Audit Deserialization Error")
                        return
                    }

                    items.forEach { item in
                        let action = item["action"] as! String
                        let entity = item["entity"] as! String
                        let data = item["data"] as! [String: Any]
                        self.syncItem(action, entity, data)
                    }
                    
                    try ProximiioOffline.shared.packageManager.build()
                    try ProximiioOffline.shared.geoManager.build()

                    NSLog("Audit Sync Complete")
                    onComplete(items.count)
                } catch {
                    NSLog("Audit Item Deserialization Error")
                }
            case .failure:
                NSLog("audit response error")
                return
            }
        }
    }
}
