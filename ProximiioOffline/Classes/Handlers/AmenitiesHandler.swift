//
//  AmenitiesHandler.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 02/11/2023.
//

import Foundation
import FlyingFox

struct AmenitiesHandler: HTTPHandler {
    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        return await HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: ProximiioOffline.shared.getAmenities()
        )
    }
}
