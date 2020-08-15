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
            self.showEmptyFields()
            return
        }
        if ((passwordTextField.text?.elementsEqual(confirmPasswordTextField.text!))! != true) {
            self.showConfirmPasswordDoesNotMatch()
            return // YA YA YA Y A YA
        }
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/registrations.json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["user":["name": nameTextField.text!, "username": usernameTextField.text!, "email": emailTextField.text!, "password": passwordTextField.text!, "confirmation-password": confirmPasswordTextField.text!]] as [String:[String: String]] // Missing params missing whatever i hate you go die
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error {
            self.showErrorContactingServer()
            print(error.localizedDescription)
        }
        let task = URLSession.shared.dataTask(with: request) { (Data, URLResponse, Error) in
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            if Error != nil {
                self.showErrorContactingServer()
                print("error=\(String(describing: Error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: Data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let userId = parseJSON["userId"] as? String
                    print("User Id: \(String(describing: userId))")
                    if (userId?.isEmpty)! {
                        self.showErrorContactingServer()
                        return
                    } else {
                        self.showRegisterComplete()
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil) 
                        }
                    }
                } else {
                    self.showErrorContactingServer()
                }
            } catch {
                self.showErrorContactingServer()
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
    
    
    // MARK: Empty Fields Alert
    func showEmptyFields() {
        let alert = UIAlertController(title: "Alert", message: "You must fill out all the fields.", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Confirm Password Does Not Match Alert
    func showConfirmPasswordDoesNotMatch() {
        
        // create the alert
        let alert = UIAlertController(title: "Alert", message: "Your confirmation password does not enter the one you have entered.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Error Contacting Server Alert
    func showErrorContactingServer() {
        
        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Register Complete Alert
    func showRegisterComplete() {
        
        // create the alert
        let alert = UIAlertController(title: "Success", message: "Your new account has been registered. Go to your email to confirm it.", preferredStyle: UIAlertController.Style.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    

}
