//
//  FirstViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet

class HomeViewController: UIViewController {  // Ah yes, home
    
    // Communicates with the api to check for any new updates
    var timer = Timer()
    let delegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        checkUser()
        // Do any additional setup after loading the view.
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    func checkUser() {
        let accessToken: String? = tokenValet.string(forKey: "Token")
        let userId: String? = myValet.string(forKey: "Id")
        if delegate.isItLoading == true {
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
                                       self.myValet.removeObject(forKey: "Id")
                                       self.tokenValet.removeObject(forKey: "Token")
                                       let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                       self.present(loginPage, animated:false, completion:nil)
                                   } else {
                                       let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                       self.present(loginPage, animated:false, completion:nil)
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
        delegate.isItLoading = false
    }

}

