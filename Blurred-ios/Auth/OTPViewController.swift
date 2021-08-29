//
//  OTPViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/11/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet

class OTPViewController: UIViewController {
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Variables
    var login = String()
    var password = String()
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.OTPCode.textContentType = .oneTimeCode
        self.navigationItem.title = "2FA"
    }
    
    // MARK: View will appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.loginButton.isEnabled = true
    }
    
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var OTPCode: UITextField!
    @IBAction func loginButtonTap(_ sender: Any) {
        self.loginButton.isEnabled = false
        loginUser()
    }
    
    // MARK: Submit OTP and login credentials
    func loginUser() {
        guard let otpCodeText = self.OTPCode.text else {
            popupMessages().showMessage(title: "Error", message: "No 2FA Code Provided", alertActionTitle: "OK", viewController: self)
            DispatchQueue.main.async {
                self.loginButton.isEnabled = true
            }
            return
        }
        let params = [
            "login": login,
            "password": password,
            "otp_attempt": otpCodeText
        ] as [String : Any]
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        AF.request("https://blurrmc.com/api/v1/sessions/", method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { (response) in
            DispatchQueue.main.async {
                myActivityIndicator.stopAnimating()
                myActivityIndicator.removeFromSuperview()
                self.loginButton.isEnabled = true
            }
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let error = JSON?["error"] as? String {
                    popupMessages().showMessage(title: "Error", message: "Invalid 2FA Code", alertActionTitle: "OK", viewController: self)
                    DispatchQueue.main.async {
                        self.loginButton.isEnabled = true
                    }
                    print(error)
                    return
                }
                let accessToken = JSON?["token"] as? String
                let errorToken = JSON?["error"] as? String
                if ((errorToken?.isEmpty) == nil) {
                    print("No error")
                } else {
                    popupMessages().showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK", viewController: self)
                    DispatchQueue.main.async {
                        self.loginButton.isEnabled = true
                    }
                }
                if accessToken?.isEmpty == nil {
                    popupMessages().showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK", viewController: self)
                    DispatchQueue.main.async {
                        self.loginButton.isEnabled = true
                    }
                } else {
                    guard let userId = JSON?["id"] as? String else { return }
                    try? self.tokenValet.setString(accessToken!, forKey: "Token")
                    try? self.myValet.setString(userId, forKey: "Id")
                    DispatchQueue.main.async {
                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return }
                        self.present(nextViewController, animated: true, completion: nil)
                    }
                }
            } catch {
                print("error code: asiojzxcv9023rwes")
            }
        }
    }

}
