//
//  ViewController.swift
//  ProximiioOffline
//
//  Created by wirrareka on 10/26/2023.
//  Copyright (c) 2023 wirrareka. All rights reserved.
//

import UIKit
import ProximiioOffline
import Proximiio

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let PROXIMIIO_TOKEN = "INSERT-TOKEN-HERE"
        
        Task {
            do {
                try await ProximiioOffline.shared.start(PROXIMIIO_TOKEN)
                
                Proximiio.sharedInstance().auth(withToken: PROXIMIIO_TOKEN) { state in
                    if (state == kProximiioReady) {
                        Proximiio.sharedInstance()?.requestPermissions(true)
                        NSLog("APP PROXIMIIO INITIALIZED")
                    }
                }
            } catch {
                NSLog("some error: \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

