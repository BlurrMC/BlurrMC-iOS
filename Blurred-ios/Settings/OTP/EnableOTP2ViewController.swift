//
//  EnableOTP2ViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet
import TTGSnackbar

class EnableOTP2ViewController: UIViewController {

    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    @IBOutlet weak var userOTPCode: UITextField!
    @IBOutlet weak var clipboardIcon: UIImageView!
    @IBOutlet weak var OTPSetupCode: UILabel!
    var otpSecret = String()
    var password = String()
    
    @IBAction func enableTapped(_ sender: Any) {
        checkOTP()
    }
    
    // MARK: Check if user's OTP code is valid
    func checkOTP() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        guard let otpCode = userOTPCode.text else {
            self.showMessage(title: "Error", message: "No 2FA Code Provided", alertActionTitle: "OK", dismiss: false)
            return
        }
        let params = [
            "password": password,
            "otp_attempt": otpCode
        ] as [String : Any]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("http://10.0.0.2:3000/api/v1/two_factor_settings/verifyotp", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let status = JSON?["status"] as? String else { return }
                switch status {
                case "Attempt is valid!":
                    DispatchQueue.main.async {
                        self.parent?.parent?.dismiss(animated: true, completion: nil)
                    }
                case "Invalid OTP attempt":
                    self.showMessage(title: "Error", message: "Invalid 2FA Code", alertActionTitle: "OK", dismiss: false)
                case "OTP not required":
                    self.showMessage(title: "Error", message: "Something went wrong! Contact support or try again later.", alertActionTitle: "Ok", dismiss: true)
                case "Invalid password":
                    self.showMessage(title: "Error", message: "Something went wrong! Contact support or try again later.", alertActionTitle: "Ok", dismiss: true)
                default:
                    break
                }
                
            } catch {
                print("error code: yiuhjbuygjhjgy")
            }
        }
    }
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        // Colors
        if traitCollection.userInterfaceStyle == .light {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.copyOTP(gesture:)))
        self.OTPSetupCode.text = otpSecret
        self.OTPSetupCode.addGestureRecognizer(tapGesture)
        self.clipboardIcon.addGestureRecognizer(tapGesture)
    }
    
    // MARK: Copy OTP Secret
    @objc func copyOTP(gesture: UIGestureRecognizer) {
        let message = TTGSnackbar(message: "Copied OTP Secret To Clipboard", duration: .short)
        message.show()
        UIPasteboard.general.string = self.otpSecret
    }
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String, dismiss: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        switch dismiss {
        case true:
            alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: {_ in
                DispatchQueue.main.async {
                    self.parent?.parent?.dismiss(animated: true, completion: nil)
                }
            }))
        case false:
            alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}
