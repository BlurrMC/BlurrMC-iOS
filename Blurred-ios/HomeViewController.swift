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

class HomeViewController: UIViewController {  // Ah yes, home
    var window: UIWindow?
    // Communicates with the api to check for any new updates
    var timer = Timer()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        checkUser() // This should always be the first thing
        timer = Timer.scheduledTimer(timeInterval: 120.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
    }
    @objc func timerAction() {
        checkUser()
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    func checkUser() {
        let accessToken: String? = tokenValet.string(forKey: "Token")
        let userId: String? = myValet.string(forKey: "Id")
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
                                   if status == "User is valid! YAY :)" {
                                    return
                                   } else if status == "User is not valid. Oh no!" {
                                    self.showInvalidSession()
                                       self.myValet.removeObject(forKey: "Id")
                                       self.tokenValet.removeObject(forKey: "Token")
                                    self.myValet.removeAllObjects()
                                    self.tokenValet.removeAllObjects()
                                       let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                       self.present(loginPage, animated:false, completion:nil)
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    self.window?.rootViewController = loginPage
                                    self.window?.makeKeyAndVisible()
                                   } else {
                                    self.showErrorContactingServer()
                                       let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                    DispatchQueue.main.async {
                                        self.present(loginPage, animated:false, completion:nil)
                                    }
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    self.window?.rootViewController = loginPage
                                    DispatchQueue.main.async {
                                        self.window?.makeKeyAndVisible()
                                    }
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
    
    func showInvalidSession() {
        self.timer.invalidate()

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Your session is invalid.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Login", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showErrorContactingServer() {
        self.timer.invalidate()

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Check your internet connection.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}

