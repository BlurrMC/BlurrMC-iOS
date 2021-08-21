//
//  SignupViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/26/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import TTGSnackbar

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
            popupMessages().showMessage(title: "Alert", message: "A field is empty. Please fill in all fields.", alertActionTitle: "OK", viewController: self)
            return
        }
        if ((passwordTextField.text?.elementsEqual(confirmPasswordTextField.text!))! != true) {
            popupMessages().showMessage(title: "Alert", message: "Confirmation passwords do not match. Try again.", alertActionTitle: "OK", viewController: self)
            return // YA YA YA Y A YA
        }
        if passwordTextField.text!.count < 6 {
            popupMessages().showMessage(title: "Alert", message: "Your password must be at least six characters long.", alertActionTitle: "OK", viewController: self)
            return
        }
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let myUrl = URL(string: "https://www.blurrmc.com/api/v1/registrations")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["user":["name": nameTextField.text!, "username": usernameTextField.text!, "email": emailTextField.text!, "password": passwordTextField.text!, "confirmation-password": confirmPasswordTextField.text!]] as [String:[String: String]] // Missing params missing whatever i hate you go die
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error {
            let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
            DispatchQueue.main.async {
                snackbar.show()
                self.SignUpButton.isEnabled = true
            }
            print(error.localizedDescription)
        }
        let task = URLSession.shared.dataTask(with: request) { (Data, URLResponse, Error) in
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            if Error != nil {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                    self.SignUpButton.isEnabled = true
                }
                print("error=\(String(describing: Error))")
                return
            }
            do {
                guard let data = Data else { return }
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let userId = parseJSON["userId"] as? String
                    if let status = parseJSON["status"] as? String{
                        if status == "User already exists" {
                            popupMessages().showMessage(title: "Error", message: "User already exsists", alertActionTitle: "OK", viewController: self)
                            DispatchQueue.main.async {
                                self.SignUpButton.isEnabled = true
                            }
                            return
                        }
                    }
                    if userId == nil {
                        popupMessages().showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK", viewController: self)
                        DispatchQueue.main.async {
                            self.SignUpButton.isEnabled = true
                        }
                        return
                    } else {
                        popupMessages().showMessage(title: "Success", message: "You have succesfully signed up.", alertActionTitle: "OK", viewController: self)
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil) 
                        }
                    }
                } else {
                    let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                        self.SignUpButton.isEnabled = true
                    }
                }
            } catch {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                    self.SignUpButton.isEnabled = true
                }
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
        self.SignUpButton.isEnabled = false
        sendSignupCreds()
    }
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.SignUpButton.isEnabled = true
    }
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // You gotta hide it (the drugs (ex. concaine))
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
    

}
