//
//  FirstViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import UserNotifications

class HomeViewController: UIViewController {
    
    // MARK: Variables
    var window: UIWindow?
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Delegates
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        checkUser() // This should always be the first thing
    }
    
    
    // MARK: Check user's account to make sure it's valid
    func checkUser() {
        let accessToken: String? = try? tokenValet.string(forKey: "Token")
        let userId: String? = try? myValet.string(forKey: "Id")
                   let Id = Int(userId!)
                       let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/isuservalid/\(Id!).json")
                       var request = URLRequest(url:myUrl!)
                       request.httpMethod = "GET"
                       request.addValue("application/json", forHTTPHeaderField: "content-type")
                       request.addValue("application/json", forHTTPHeaderField: "Accept")
                       request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
                       let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                           if error != nil {
                               print("there is an error")
                               return
                           }
                           
                           do {
                               let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                               if let parseJSON = json {
                                   let status: String? = parseJSON["status"] as? String
                                switch status {
                                case "User is valid! YAY :)":
                                    return
                                case "User is not valid. Oh no!":
                                    try self.myValet.removeObject(forKey: "Id")
                                    try self.tokenValet.removeObject(forKey: "Token")
                                    try self.myValet.removeAllObjects()
                                    try self.tokenValet.removeAllObjects()
                                       let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                       self.present(loginPage, animated:false, completion:nil)
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    self.window?.rootViewController = loginPage
                                    self.window?.makeKeyAndVisible()
                                case .none:
                                    if let httpResponse = response as? HTTPURLResponse {
                                        if httpResponse.statusCode == 401 {
                                            try self.myValet.removeObject(forKey: "Id")
                                            try self.tokenValet.removeObject(forKey: "Token")
                                            try self.myValet.removeAllObjects()
                                            try self.tokenValet.removeAllObjects()
                                            self.window =  UIWindow(frame: UIScreen.main.bounds)
                                            DispatchQueue.main.async {
                                                let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                                self.present(loginPage, animated:false, completion:nil)
                                                self.window?.rootViewController = loginPage
                                                self.window?.makeKeyAndVisible()
                                            }
                                        } else {
                                            self.showErrorContactingServer()
                                        }
                                    }
                                case .some(_):
                                    break
                                }
                               } else {
                                   return
                               }
                           } catch {
                               return
                           }
                       }
                   task.resume()
    }
    
    
    // Error Contacting Server Alert
    func showErrorContactingServer() {
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Check your internet connection.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}

