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
        Proximiio.sharedInstance().auth(withToken:token) { state in
            if (state == kProximiioReady) {
                NSLog("Proximi.io Offline API ProximiioSDK Instance Authorized")
                DispatchQueue.main.async {
                    onComplete(true)
                }
            } else {
                NSLog("Proximi.io Offline API ProximiioSDK Authorization Failed")
                DispatchQueue.main.async {
                    onComplete(false)
                }
            }
        }
    }
}
