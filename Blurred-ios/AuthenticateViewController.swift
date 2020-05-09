//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AuthenticateViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    // CRAP I forgot to declare these until now ^^^
    
    // Has to contact the devise api sending it's credentials to make sure it's good then it sends a token back

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        // Do any additional setup after loading the view.
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
            sendCreds()
        }
        return true
    }
    @available(iOS 13.0, *)
    @IBAction func SubmitCreds(_ sender: UIButton) {
        sendCreds()
    }
  
    func sendCreds() {
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if (username?.isEmpty)! || (password?.isEmpty)! {
            print("Username \(String(describing: username)) or password \(String(describing: password)) is empty")
            showEmptyAlert()
             
            
            return
        }
        // MAKE THE PEOPLE WAIT GOD DAMN IT
        
        if #available(iOS 13.0, *) {
            let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
            myActivityIndicator.center = view.center
            myActivityIndicator.hidesWhenStopped = true
            myActivityIndicator.startAnimating()
            view.addSubview(myActivityIndicator)
            
        } else {
            // nothing
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
            showErrorContactingServer() // WHAT DID THE PEOPLE DO?
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in // error. Error? ERRORRRR???!!??!?!
            if error != nil {
                self.showNoResponseFromServer() // LOL probably some kids wifi router in the attic.
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let userId = parseJSON["id"] as? Int
                    let accessToken = parseJSON["token"] as? String
                    let errorToken = parseJSON["error"] as? String
                    print(userId)
                    if ((errorToken?.isEmpty) == nil) {
                        print("No error")
                    } else {
                        self.showIncorrectCreds()
                    }
                    let saveAccessToken: Bool = KeychainWrapper.standard.set(accessToken!, forKey: "accessToken")
                    let saveUserId: Bool = KeychainWrapper.standard.set(userId!, forKey: "userId")  // Ignore these error messages it's just swift being a little baby
                    DispatchQueue.main.async {
                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
                        self.present(nextViewController, animated: true, completion: nil)
                    }
                } else {  // else what?
                    self.showNoResponseFromServer() // if If IF IF WHTA??
                    print(error ?? "No error")
                }
                
            } catch {
                self.showErrorContactingServer()
                print(error)
            }
        }
        task.resume()
    }
    func showEmptyAlert() {

        // create the alert
        let alert = UIAlertController(title: "Alert", message: "The username or password is missing.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showIncorrectCreds() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Wrong username or password.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }

}
