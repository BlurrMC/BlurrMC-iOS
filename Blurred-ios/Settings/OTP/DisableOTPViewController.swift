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
    }
    
    @IBAction func disabledTapped(_ sender: Any) {
        self.deleteOTP()
    }
    
    func deleteOTP() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        guard let otpCodeText = self.OTPCode.text else {
            popupMessages().showMessage(title: "Error", message: "No 2FA Code Provided", alertActionTitle: "OK", viewController: self)
            return
        }
        guard let password = passwordTextField.text else {
            popupMessages().showMessage(title: "Error", message: "No Password Provided", alertActionTitle: "OK", viewController: self)
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
        AF.request("https://blurrmc.com/api/v1/two_factor_settings", method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let _ = JSON?["error"] as? String {
                    popupMessages().showMessage(title: "Error", message: "Invalid 2FA Code or Password", alertActionTitle: "OK", viewController: self)
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

}
