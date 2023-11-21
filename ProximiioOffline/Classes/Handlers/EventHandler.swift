//
//  EventHandler.swift
//  ProximiioOffline_Example
//
//  Created by Matej Drzik on 27/10/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import FlyingFox

public struct EventHandler: HTTPHandler {
    let resource = "event"
    
    func save(_ data: Data) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(resource)-\(Date().timeIntervalSince1970).json"
        let path = directory.appendingPathComponent("\(resource)s-buffer").appendingPathComponent(fileName).path
        FileManager.default.createFile(atPath: path, contents: data)
    }
    
    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let data = try await request.bodyData;
        save(data)
        let body = try JSONSerialization.data(withJSONObject: [ "success": true ])
        let response = HTTPResponse(statusCode: .ok, body: body)
        return response
    }
}
