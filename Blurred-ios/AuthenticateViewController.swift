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
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    // CRAP I forgot to declare these until now ^^^
    // Has to contact the devise api sending it's credentials to make sure it's good then it sends a token back

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField?.delegate = self
        passwordTextField?.delegate = self
        usernameTextField?.tag = 0
        passwordTextField?.tag = 1
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func SubmitCreds(_ sender: UIButton) {
        sendCreds()
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    // MARK: Send credentials to login
    func sendCreds() {
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if (username?.isEmpty)! || (password?.isEmpty)! {
            print("Username \(String(describing: username)) or password \(String(describing: password)) is empty")
            self.showEmptyAlert() // WHAT DID THE PEOPLE DO?

             
            
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
            self.showErrorContactingServer() // WHAT DID THE PEOPLE DO?
            removeActivityIndicator(activityIndicator: myActivityIndicator)
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in // error. Error? ERRORRRR???!!??!?!
            if error != nil {
                self.showNoResponseFromServer()
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let userIdInt = parseJSON["id"] as? Int
                    if userIdInt == nil {
                        self.showIncorrectCreds()
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    } else {
                        let userId = "\(userIdInt!)"
                        let accessToken = parseJSON["token"] as? String
                        let errorToken = parseJSON["error"] as? String
                        print(userId)
                        if ((errorToken?.isEmpty) == nil) {
                            print("No error")
                        } else {
                            self.showIncorrectCreds()
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        }
                        if accessToken?.isEmpty == nil {
                            self.showIncorrectCreds()
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        } else {
                            try? self.tokenValet.setString(accessToken!, forKey: "Token")
                            try? self.myValet.setString(userId, forKey: "Id")
                            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                            DispatchQueue.main.async {
                                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
                                self.present(nextViewController, animated: true, completion: nil)
                            }
                        }
                    }
                } else {  // else what?
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.showNoResponseFromServer()
                    print(error ?? "No error")
                }
                
            } catch {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                self.showErrorContactingServer()
                print(error)
            }
        }
        task.resume()
    }
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    func showEmptyAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Alert", message: "The username or password is missing.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showErrorContactingServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showNoResponseFromServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showIncorrectCreds() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Alert", message: "Wrong username or password.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
}
