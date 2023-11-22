//
//  ProximiioOffline+Routes.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import FlyingFox

extension ProximiioOffline {
    func add_routes(_ server: HTTPServer) async {
        if Bundle.main.url(forResource: path, withExtension: nil) != nil {
            let fontHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/fonts", serverPath: "fonts")
            await server.appendRoute("GET /fonts/*", to: fontHandler)
            
            let dataHandler = CustomDirectoryHandler(bundle: Bundle.main, subPath: "\(path)/data", serverPath: "data")
            await server.appendRoute("GET /data/*", to: dataHandler)
        }
        
        await server.appendRoute("GET /core/current_user", to: .file(named: "\(path)/core/current_user"))
        await server.appendRoute("GET /core/package", to: PackageHandler())
        await server.appendRoute("GET /core/campuses", to: CampusesHandler())
        await server.appendRoute("GET /v5/geo/amenities", to: AmenitiesHandler())
        await server.appendRoute("GET /v5/geo/amenity_categories", to: AmenityCategoriesHandler())
        await server.appendRoute("GET /v5/geo/features", to: FeaturesHandler())
        await server.appendRoute("GET /v5/geo/styles/default", to: StyleHandler())
        
        await server.appendRoute("POST /core/visitors", to: VisitorHandler())
        await server.appendRoute("POST /core/events", to: EventHandler())
        await server.appendRoute("POST /core/events/batch", to: EventHandler())
        await server.appendRoute("POST /core/positions/batch", to: PositionHandler())
        await server.appendRoute("POST /v5/geo/wayfinding_logs", to: WayfindingLogHandler())
        await server.appendRoute("POST /v5/geo/search_logs", to: SearchLogHandler())
    }
}
