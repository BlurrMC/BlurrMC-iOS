//
//  DisableOTPViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet

class DisableOTPViewController: UIViewController {
    
    @IBOutlet weak var OTPCode: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }
    
    @IBAction func disabledTapped(_ sender: Any) {
        self.deleteOTP()
    }
    
    func deleteOTP() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        guard let otpCodeText = self.OTPCode.text else {
            self.showMessage(title: "Error", message: "No 2FA Code Provided", alertActionTitle: "OK")
            return
        }
        guard let password = passwordTextField.text else {
            self.showMessage(title: "Error", message: "No Password Provided", alertActionTitle: "OK")
            return
        }
        let params = [
            "password": password,
            "otp_attempt": otpCodeText
        ] as [String : Any]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        AF.request("http://10.0.0.2:3000/api/v1/two_factor_settings", method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let _ = JSON?["error"] as? String {
                    self.showMessage(title: "Error", message: "Invalid 2FA Code or Password", alertActionTitle: "OK")
                    return
                }
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            } catch {
                print("error code: asdf98uiqnjaksd")
            }
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
