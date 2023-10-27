//
//  CustomDirectoryHandler.swift
//  ProximiioOffline_Example
//
//  Created by Matej Drzik on 27/10/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import FlyingFox

public struct CustomDirectoryHandler: HTTPHandler {

    @UncheckedSendable
    private(set) var root: URL?
    let serverPath: String

    public init(root: URL, serverPath: String = "/") {
        self.root = root
        self.serverPath = serverPath
    }

    public init(bundle: Bundle, subPath: String = "", serverPath: String) {
        self.root = bundle.resourceURL?.appendingPathComponent(subPath)
        self.serverPath = serverPath
    }

    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard
            let filePath = makeFileURL(for: request.path),
            let data = try? Data(contentsOf: filePath) else {
            return HTTPResponse(statusCode: .notFound)
        }

        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: data
        )
    }

    func makeFileURL(for requestPath: String) -> URL? {
        let compsA = serverPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")

        let compsB = requestPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")

        guard compsB.hasPrefix(compsA) else { return nil }
        let subPath = String(compsB.dropFirst(compsA.count))
        return root?.appendingPathComponent(subPath)
    }
}
