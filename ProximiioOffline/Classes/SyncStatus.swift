//
//  SyncStatus.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation
import StorageDone

struct SyncStatus: Codable, PrimaryKey {
    let id: String
    let lastSync: Int64
    
    func primaryKey() -> String {
        return "id"
    }
}
