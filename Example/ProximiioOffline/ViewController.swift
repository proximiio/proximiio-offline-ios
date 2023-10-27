//
//  ViewController.swift
//  ProximiioOffline
//
//  Created by wirrareka on 10/26/2023.
//  Copyright (c) 2023 wirrareka. All rights reserved.
//

import UIKit
import ProximiioOffline

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ProximiioOffline.shared.setPath("offline_data")
        ProximiioOffline.shared.setToken("INSERT TOKEN HERE");
        
        Task {
            do {
                try await ProximiioOffline.shared.start()
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

