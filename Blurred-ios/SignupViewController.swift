//
//  SignupViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/26/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var SignUpButton: UIButton!
    @IBAction func BackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    func sendSignupCreds() {
        // Setup the api over here.
    }
    // Setup the Devise api to accept sign ups through the api. Shouldn't be hard, right?????!
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
        

        // Do any additional setup after loading the view.
    }
    // self.view.endEditing(true)
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
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
