//
//  ProximiioOffline+Proximiio.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import Proximiio

extension ProximiioOffline {
    func initProximiio(_ address: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            ProximiioAPI.sharedManager()?.setApi(address)
            ProximiioAPI.sharedManager()?.setApiVersion("v5")
            ProximiioMapStyle.cs_deleteFromDB(withCondition: "")
            NSLog("Proximi.io Offline API Authorizing ProximiioSDK Instance")
            Proximiio.sharedInstance().auth(withToken:token) { state in
                if (state == kProximiioReady) {
                    NSLog("Proximi.io running sync")
                    Proximiio.sharedInstance().sync { success in
                        NSLog("Proximi.io sync success: \(success)")
                        if (success) {
                            NSLog("Proximi.io Offline API ProximiioSDK Instance Authorized")
                            continuation.resume(returning: true)
                            
                        } else {
                            NSLog("Proximi.io Offline API ProximiioSDK Synchronization Failed")
                            continuation.resume(returning: false)
                        }
                    }
                } else {
                    NSLog("Proximi.io Offline API ProximiioSDK Authorization Failed")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
