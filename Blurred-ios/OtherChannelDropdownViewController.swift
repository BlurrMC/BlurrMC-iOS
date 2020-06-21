//
//  OtherChannelDropdownViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/14/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class OtherChannelDropdownViewController: UIViewController {
    
    var Following: Bool = false

    @IBOutlet weak var blockButtton: UIButton!
    @IBOutlet weak var followbuttton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        blockButtton.layer.cornerRadius = 12
        followbuttton.layer.cornerRadius = 12

    }
    
    func checkFollowing() {
        if Following == false {
            followbuttton.setTitle("Folllow", for: .normal)
        } else if Following == true {
            followbuttton.setTitle("Unfollow", for: .normal)
        }
    }
}
