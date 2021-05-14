//
//  EnableOTP2ViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire

class EnableOTP2ViewController: UIViewController {

    @IBOutlet weak var userOTPCode: UITextField!
    @IBOutlet weak var clipboardIcon: UIImageView!
    @IBOutlet weak var OTPSetupCode: UILabel!
    var password = String()
    
    @IBAction func enableTapped(_ sender: Any) {
        // Send OTP_attempt (and previous password) to make sure that user can login
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
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}
