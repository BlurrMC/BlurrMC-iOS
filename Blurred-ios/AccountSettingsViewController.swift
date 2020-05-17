//
//  AccountSettingsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/16/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Foundation
import Valet

class AccountSettingsViewController: UIViewController {

    @IBAction func editButtonTapped(_ sender: Any) {
        updateAccount()
    }
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var bioField: UITextField!
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    // Check to see if any of the text fields have changed and if they have then 
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    func updateAccount() {
        startRequest()
    }
    func startRequest() {
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let userId: String? = myValet.string(forKey: "Id")
        let token: String? = tokenValet.string(forKey: "Token")
        let Id = Int(userId!)
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/registrations/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        if nameField?.text?.isEmpty != true {
            let name = nameField.text
            let patchString = ["name": name!] as [String: String]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.showErrorContactingServer()
                return
            }
        }
        if usernameField?.text?.isEmpty != true {
            let username = usernameField.text
            let patchString = ["username": username!] as [String: String]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.showErrorContactingServer()
                return
            }
        }
        if emailField?.text?.isEmpty != true {
            let email = emailField.text
            let patchString = ["email": email!] as [String: String]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.showErrorContactingServer()
                return
            }
        }
        if bioField?.text?.isEmpty != true {
            let bio = bioField.text
            let patchString = ["bio": bio!] as [String: String]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.showErrorContactingServer()
                return
            }
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                self.showNoResponseFromServer()
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let returnCode = parseJSON["status"] as? String
                    if returnCode != String("User confirmed successfully") {
                        self.showErrorContactingServer()
                    }
                } else {
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
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
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
}
