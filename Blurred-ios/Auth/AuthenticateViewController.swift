//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import TTGSnackbar

class AuthenticateViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField?.delegate = self
        passwordTextField?.delegate = self
        usernameTextField?.tag = 0
        passwordTextField?.tag = 1
        self.passwordTextField.textContentType = .password
        self.usernameTextField.textContentType = .username
    }
    
    
    // MARK: Text Field Should Return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: Submit Creds Button Tapped
    @IBAction func SubmitCreds(_ sender: UIButton) {
        sender.isEnabled = false
        sendCreds()
    }
    
    
    // MARK: Send credentials to login
    func sendCreds() {
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if (username?.isEmpty)! || (password?.isEmpty)! {
            print("Username \(String(describing: username)) or password \(String(describing: password)) is empty")
            popupMessages().showMessage(title: "Alert", message: "Username or password is empty.", alertActionTitle: "OK", viewController: self)
            return
        }
        // MAKE THE PEOPLE WAIT GOD DAMN ITz
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }

        // Contact the server about the people ^ (if u don't they gonna be sad)
        let myUrl = URL(string: "https://blurrmc.com/api/v1/sessions")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["login": username!, "password": password!] as [String: String]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error { // Catch the VICTORY ROYALE
            print(error.localizedDescription) // I hope it doesn't screw up
            let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
            DispatchQueue.main.async {
                snackbar.show()
                self.loginButton.isEnabled = true
            }
            removeActivityIndicator(activityIndicator: myActivityIndicator)
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in // error. Error? ERRORRRR???!!??!?!
            if error != nil {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later. (sorry!)", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                    self.loginButton.isEnabled = true
                }
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let status = parseJSON["error"] as? String
                    if status == "Invalid OTP code" {
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "showOTP", sender: self)
                        }
                        return
                    } else if status == "invalid_credentials" {
                        popupMessages().showMessage(title: "Invalid Credentials", message: "You put in the wrong login information.", alertActionTitle: "OK", viewController: self)
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        DispatchQueue.main.async {
                            self.loginButton.isEnabled = true
                        }
                        return
                    }
                    let userId = parseJSON["id"] as? String
                    if userId == nil {
                        popupMessages().showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK", viewController: self)
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        DispatchQueue.main.async {
                            self.loginButton.isEnabled = true
                        }
                    } else {
                        let accessToken = parseJSON["token"] as? String
                        let errorToken = parseJSON["error"] as? String
                        if ((errorToken?.isEmpty) == nil) {
                            print("No error")
                        } else {
                            popupMessages().showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK", viewController: self)
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            DispatchQueue.main.async {
                                self.loginButton.isEnabled = true
                            }
                        }
                        if accessToken?.isEmpty == nil {
                            popupMessages().showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK", viewController: self)
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            DispatchQueue.main.async {
                                self.loginButton.isEnabled = true
                            }
                        } else {
                            guard let userId = userId else { return }
                            try? self.tokenValet.setString(accessToken!, forKey: "Token")
                            try? self.myValet.setString(userId, forKey: "Id")
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            if ((try? self.myValet.string(forKey: "EULAAgreed") == "true") != nil) {
                                DispatchQueue.main.async {
                                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                    guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return } /// Using segue would be better, but I don't have time to change that. It's 8:55 pm. Definetly past my bed time.
                                    self.present(nextViewController, animated: true, completion: nil)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "showEULA", sender: self)
                                }
                            }
                            
                        }
                    }
                } else {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    print(error ?? "No error")
                    DispatchQueue.main.async {
                        self.loginButton.isEnabled = true
                    }
                }
                
            } catch {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                    self.loginButton.isEnabled = true
                }
                print(error)
            }
        }
        task.resume()
    }
    
    // MARK: Pass data through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case is OTPViewController:
            let vc = segue.destination as? OTPViewController
            if segue.identifier == "showOTP" {
                guard let login = self.usernameTextField.text else { return }
                guard let password = self.passwordTextField.text else { return }
                vc?.login = login
                vc?.password = password
            }
        default:
            break
        }
    }
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        self.loginButton.isEnabled = true
    }
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }

}
