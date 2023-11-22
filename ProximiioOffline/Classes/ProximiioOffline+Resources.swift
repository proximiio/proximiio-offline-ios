//
//  ProximiioOffline+Resources.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation

extension ProximiioOffline {
    public func getPackage() -> Data {
        return self.packageManager.packageJSON
    }
    
    public func getCampuses() -> Data {
        return self.packageManager.campusesJSON
    }
    
    public func getAmenities() -> Data {
        return self.geoManager.amenitiesJSON
    }
    
    public func getAmenityCategories() -> Data {
        return self.geoManager.amenityCategoriesJSON
    }
    
    public func getFeatures() -> Data {
        return self.geoManager.featuresJSON
    }
    
    public func getStyle() -> Data {
        return self.geoManager.styleJSON
    }
}
