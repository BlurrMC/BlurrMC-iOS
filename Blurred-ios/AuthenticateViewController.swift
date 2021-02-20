//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet

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
        sendCreds()
    }
    
    
    // MARK: Send credentials to login
    func sendCreds() {
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if (username?.isEmpty)! || (password?.isEmpty)! {
            print("Username \(String(describing: username)) or password \(String(describing: password)) is empty")
            self.showMessage(title: "Alert", message: "Username or password is empty.", alertActionTitle: "OK")

             
            
            return
        }
        // MAKE THE PEOPLE WAIT GOD DAMN ITz
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }

        // Contact the server about the people ^ (if u don't they gonna be sad)
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/sessions.json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["login": username!, "password": password!] as [String: String]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error { // Catch the VICTORY ROYALE
            print(error.localizedDescription) // I hope it doesn't screw up
            self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
            removeActivityIndicator(activityIndicator: myActivityIndicator)
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in // error. Error? ERRORRRR???!!??!?!
            if error != nil {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let userIdInt = parseJSON["id"] as? Int
                    if userIdInt == nil {
                        self.showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK")
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    } else {
                        let userId = "\(userIdInt!)"
                        let accessToken = parseJSON["token"] as? String
                        let errorToken = parseJSON["error"] as? String
                        print(userId)
                        if ((errorToken?.isEmpty) == nil) {
                            print("No error")
                        } else {
                            self.showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK")
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        }
                        if accessToken?.isEmpty == nil {
                            self.showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK")
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        } else {
                            try? self.tokenValet.setString(accessToken!, forKey: "Token")
                            try? self.myValet.setString(userId, forKey: "Id")
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            DispatchQueue.main.async {
                                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return } /// Using segue would be better, but I don't have time to change that. It's 8:55 pm. Too bad!
                                self.present(nextViewController, animated: true, completion: nil)
                            }
                        }
                    }
                } else {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    print(error ?? "No error")
                }
                
            } catch {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
                print(error)
            }
        }
        task.resume()
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
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
