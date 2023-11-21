//
//  OfflineModel.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation
import StorageDone

enum OfflineModelError: Error {
    case dataParsing
    case jsonParsing
}

struct OfflineModel: Codable, PrimaryKey {
    let id: String
    let data: String
    let type: String
    
    init(id: String, data: String, type: String) {
        self.id = id
        self.data = data
        self.type = type
    }
    
    func primaryKey() -> String {
        return "id"
    }
    
    func json() throws -> [String: Any] {
        guard let data = data.data(using: .utf8) else {
            throw OfflineModelError.dataParsing
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OfflineModelError.jsonParsing
        }
        
        return json ?? [:]
    }
}
