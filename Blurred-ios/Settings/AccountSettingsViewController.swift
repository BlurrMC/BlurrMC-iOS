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
    
    
    // MARK: Edit Button Tapped
    @IBAction func editButtonTapped(_ sender: Any) {
        updateAccount()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var bioField: UITextField!
    
    // MARK: Back Button Tapped
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
        self.nameField.textContentType = .name
        self.usernameField.textContentType = .username
        self.emailField.textContentType = .emailAddress
    }
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    // Check to see if any of the text fields have changed and if they have then
    
    
    // MARK: Remove Activity Indicatory
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    
    // MARK: Update Account
    func updateAccount() {
        startRequest()
    }
    
    
    // MARK: Upload the changed information
    func startRequest() {
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let userId: String? = try? myValet.string(forKey: "Id")
        let token: String? = try? tokenValet.string(forKey: "Token")
        let Id = Int(userId!)
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/registrations/\(Id!).json")
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
                return
            }
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let returnCode = parseJSON["status"] as? String
                    if returnCode != String("User confirmed successfully") {
                        return
                    }
                } else {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    print(error ?? "No error")
                }
            } catch {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                print(error)
            }
        }
        task.resume()
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    
}
