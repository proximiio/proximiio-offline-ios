//
//  ProximiioOffline+Proximiio.swift
//  ProximiioOffline
//
//  Created by Matej Drzik on 22/11/2023.
//

import Foundation
import Proximiio

extension ProximiioOffline {
    func initProximiio(_ address: String, onComplete: @escaping (Bool) -> Void) {
        NSLog("Proximi.io Offline API Authorizing ProximiioSDK Instance")
        (ProximiioAPI.sharedManager())?.setApi(address)
        (ProximiioAPI.sharedManager())?.setApiVersion("v5")
        let lastSync = getLastSync()
        
        Proximiio.sharedInstance().auth(withToken:token) { state in
            if (state == kProximiioReady) {
                if (lastSync == 0) {
                    Proximiio.sharedInstance().sync { success in
                        if (success) {
                            DispatchQueue.main.async {
                                NSLog("Proximi.io Offline API ProximiioSDK Instance Authorized")
                                onComplete(true)
                            }
                        } else {
                            NSLog("Proximi.io Offline API ProximiioSDK Synchronization Failed")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        NSLog("Proximi.io Offline API ProximiioSDK Instance Authorized")
                        onComplete(true)
                    }
                }
                NSLog("Proximi.io Offline API ProximiioSDK Instance Authorized")
            } else {
                NSLog("Proximi.io Offline API ProximiioSDK Authorization Failed")
                DispatchQueue.main.async {
                    onComplete(false)
                }
            }
        }
    }
}
