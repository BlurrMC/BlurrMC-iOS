//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AuthenticateViewController: UIViewController {
    
    @IBOutlet weak internal var usernameCredsField: UITextField!
    @IBOutlet weak internal var passwordCredsField: UITextField!
    // CRAP I forgot to declare these until now ^^^
    
    // Has to contact the devise api sending it's credentials to make sure it's good then it sends a token back

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        // Do any additional setup after loading the view.
        usernameCredsField.delegate = self
        passwordCredsField.delegate = self
    }

    @IBAction func SubmitCreds(_ sender: UIButton) {
        let username = usernameCredsField.text
        let password = passwordCredsField.text
        
        if (username?.isEmpty)! || (password?.isEmpty)! {
            print("Username \(String(describing: username)) or password \(String(describing: password)) is empty")
             
            
            return
        }
        // MAKE THE PEOPLE WAIT GOD DAMN IT
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = false
        myActivityIndicator.startAnimating()
        view.addSubview(myActivityIndicator)
        // Contact the server about the people ^ (if u don't they gonna be sad)
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/sessions/")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let postString = ["username": username!, "password": password!] as [String: String]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error { // Catch the VICTORY ROYALE
            print(error.localizedDescription) // I hope it doesn't screw up
            displayMessage(userMessage: "Something went wrong!") // WHAT DID THE PEOPLE DO?
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in // error. Error? ERRORRRR???!!??!?!
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            if error != nil {
                self.displayMessage(userMessage: "Could not contact the server. Try again later.") // LOL probably some kids wifi router in the attic.
                print("error=\(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let accessToken = parseJSON["token"] as? String
                    let userId = parseJSON["id"] as? String
                    print("Access token: \(String(describing: accessToken!))")
                    let saveAccessToken: Bool = KeychainWrapper.standard.set(accessToken!, forKey: "accessToken")
                    let saveUserId: Bool = KeychainWrapper.standard.set(userId!, forKey: "userId")
                    print("The access token: \(saveAccessToken)")
                    print("The user id: \(saveUserId)")
                    if (accessToken?.isEmpty)! {
                        self.displayMessage(userMessage: "Server error. Please try again later.")
                        return
                    }
                    DispatchQueue.main.async {
                        let homePage = self.storyboard?.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
                        let appDelegate = UIApplication.shared.delegate
                        appDelegate?.window??.rootViewController = homePage
                    }
                } else {  // else what?
                    self.displayMessage(userMessage: "Try again later.") // if If IF IF WHTA??
                }
                
            } catch {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                self.displayMessage(userMessage: "Error contacting the server. Try again later.")
                print(error)
            }
        }
        task.resume()
            
        
    }
    
    func displayMessage(userMessage:String) -> Void {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Alert", message: userMessage, preferredStyle: .alert)  // Oh hi mark!
            
            let OKAction = UIAlertAction(title: "OK", style: .default) {
            (action: UIAlertAction!) in
            print("Ok button tapped")  // "ok", very funny
                DispatchQueue.main.sync {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
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
extension AuthenticateViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
