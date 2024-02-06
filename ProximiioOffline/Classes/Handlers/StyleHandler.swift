//
//  StyleHandler.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 02/11/2023.
//

import Foundation
import FlyingFox

struct StyleHandler: HTTPHandler {
    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {        
        return await await HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: ProximiioOffline.shared.getStyle()
        )
    }
}
