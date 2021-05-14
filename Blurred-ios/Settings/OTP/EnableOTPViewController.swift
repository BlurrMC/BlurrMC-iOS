//
//  EnableOTPViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire

class EnableOTPViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBAction func enableButtonTapped(_ sender: Any) {
        // Send password and start create action for OTP
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Colors
        if traitCollection.userInterfaceStyle == .light {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }

}
