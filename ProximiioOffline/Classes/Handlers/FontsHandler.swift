//
//  VisitorHandler.swift
//  ProximiioOffline_Example
//
//  Created by Matej Drzik on 27/10/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import FlyingFox

public struct FontsHandler: HTTPHandler {
    let resource = "visitor"
    
    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        NSLog("fonts handler request path: \(request.path) headers: \(request.headers)  query: \(request.query)")
        let body = try JSONSerialization.data(withJSONObject: [ "success": true ])
        let response = HTTPResponse(statusCode: .ok, body: body)
        return response
    }
}
