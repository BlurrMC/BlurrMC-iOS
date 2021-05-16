//
//  SignupViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/26/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Outlets
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var SignUpButton: UIButton!
    
    
    // MARK: Back Button Tapped
    @IBAction func BackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Send the new user's information
    func sendSignupCreds() {
        // Setup the api over here.
        if (nameTextField.text?.isEmpty)! ||
            (usernameTextField.text?.isEmpty)! ||
            (emailTextField.text?.isEmpty)! ||
            (passwordTextField.text?.isEmpty)! ||
            (confirmPasswordTextField.text?.isEmpty)! {
            self.showMessage(title: "Alert", message: "A field is empty. Please fill in all fields.", alertActionTitle: "OK")
            return
        }
        if ((passwordTextField.text?.elementsEqual(confirmPasswordTextField.text!))! != true) {
            self.showMessage(title: "Alert", message: "Confirmation passwords do not match. Try again.", alertActionTitle: "OK")
            return // YA YA YA Y A YA
        }
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/registrations")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["user":["name": nameTextField.text!, "username": usernameTextField.text!, "email": emailTextField.text!, "password": passwordTextField.text!, "confirmation-password": confirmPasswordTextField.text!]] as [String:[String: String]] // Missing params missing whatever i hate you go die
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error {
            self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
            print(error.localizedDescription)
        }
        let task = URLSession.shared.dataTask(with: request) { (Data, URLResponse, Error) in
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            if Error != nil {
                self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
                print("error=\(String(describing: Error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: Data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let userId = parseJSON["userId"] as? String
                    print("User Id: \(String(describing: userId))")
                    if (userId?.isEmpty)! {
                        self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
                        return
                    } else {
                        self.showMessage(title: "Success", message: "You have succesfully signed up.", alertActionTitle: "OK")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil) 
                        }
                    }
                } else {
                    self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
                }
            } catch {
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
    
    
    // MARK: Sign Up Button Tapped
    @IBAction func signUpButtonTapped(_ sender: Any) {
        sendSignupCreds()
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // You gotta hide it
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "Sign Up"
        confirmPasswordTextField?.delegate = self
        passwordTextField?.delegate = self
        emailTextField?.delegate = self
        usernameTextField?.delegate = self
        nameTextField?.delegate = self
        nameTextField?.tag = 0
        usernameTextField?.tag = 1
        emailTextField?.tag = 2
        passwordTextField?.tag = 3
        confirmPasswordTextField?.tag = 4
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
        self.nameTextField.textContentType = .name
        self.usernameTextField.textContentType = .username
        self.emailTextField.textContentType = .emailAddress
        self.passwordTextField.textContentType = .newPassword
        self.passwordTextField.textContentType = .password
    }
    
    
    // MARK: Text Field Should Return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            usernameTextField.becomeFirstResponder()
        } else if textField == usernameTextField {
            textField.resignFirstResponder()
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            confirmPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
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
