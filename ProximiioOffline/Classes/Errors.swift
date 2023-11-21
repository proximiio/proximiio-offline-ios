//
//  Errors.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation

enum ManagerError: Error {
    case fileMissing
    case invalidFileAccess
    case invalidJSON
    case buildError
}
