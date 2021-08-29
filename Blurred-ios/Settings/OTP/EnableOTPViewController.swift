//
//  EnableOTPViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet
import TTGSnackbar

class EnableOTPViewController: UIViewController {
    
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    var backupCodes = [String]()
    var otpSecret = String()
    var password = String()

    @IBOutlet weak var passwordField: UITextField!
    @IBAction func enableButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Alert", message: "Are you sure? Your account may get locked if process is interrupted.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {_ in
            self.dismiss(animated: true, completion: nil)
            return
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: {_ in
            self.enableOTP()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Enable the OTP
    func enableOTP() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        guard let password = passwordField.text else {
            popupMessages().showMessage(title: "Error", message: "No Password Provided", alertActionTitle: "OK", viewController: self)
            return
        }
        let params = [
            "password": password
        ] as [String : Any]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/two_factor_settings", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                return
            }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let status = JSON?["status"] as? String, status == "Incorrect password" {
                    popupMessages().showMessage(title: "Error", message: "Your password was incorrect", alertActionTitle: "OK", viewController: self)
                    return
                }
                guard let backupCodes = JSON?["backupcodes"] as? [String] else { return }
                guard let otpSecret = JSON?["otpsecret"] as? String else { return }
                self.backupCodes = backupCodes
                self.otpSecret = otpSecret
                self.password = password
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "partTwoOTP", sender: self)
                }
            } catch {
                print("error code: asdfi98juewfiajsd")
            }
        }
    }
    
    
    // MARK: View did load
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: Pass data through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case is OTPViewController:
            let vc = segue.destination as? EnableOTP2ViewController
            if segue.identifier == "verifyOTP" {
                vc?.otpSecret = otpSecret
                vc?.password = password
            }
        default:
            break
        }
    }

}
