//
//  PackageHandler.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 01/11/2023.
//

import Foundation
import FlyingFox

struct PackageHandler: HTTPHandler {
    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: ProximiioOffline.shared.getPackage()
        )
    }
}
