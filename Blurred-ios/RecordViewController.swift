//
//  RecordViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Foundation

class RecordViewController: UIViewController {
    
    

    @IBAction func galleryButtonPress(_ sender: Any) {
    }
    @IBAction func recordButtonPress(_ sender: Any) {
    }
    @IBAction func recordBackButton(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        // Saves the video to gallery and then uploads that video from gallery. The user doesn't have to pick that they are uploading it from gallery though.
    }
}
