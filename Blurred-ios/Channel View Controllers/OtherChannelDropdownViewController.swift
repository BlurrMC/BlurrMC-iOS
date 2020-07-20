//
//  OtherChannelDropdownViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/14/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet

class OtherChannelDropdownViewController: UIViewController {
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    @IBAction func followButton(_ sender: Any) {
        checkClicked()
    }
    @IBAction func blockButton(_ sender: Any) {
        
    }
    var chanelVar = String()
    var Following = Bool()
    // Put user id and other party id over here so checkclicked and follow/unfollow the party.
    func checkClicked() {
        if Following == true {
            // Make user unfollow the other party
            Following = false
        } else if Following != true {
            // Make user follow the other party
            Following = true
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkIfUserIsFollowing()
        checkFollowing()
    }
    func checkIfUserIsFollowing() {
        let accessToken: String? = try? tokenValet.string(forKey: "Token")
                       let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/isuserfollowing/\(chanelVar).json")
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
                                print("\(String(describing: status))")
                                DispatchQueue.main.async {
                                    if status == "User is not following." {
                                        self.Following = false
                                    } else if status == "User is following." {
                                        self.Following = true
                                    } else {
                                        self.showErrorContactingServer()
                                    }
                                }
                               } else {
                                print("smolchungus")
                                   return
                               }
                           } catch {
                            print("this is hell")
                               return
                           }
                       }
                   task.resume()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        Following = false
    }
    @IBOutlet weak var blockButtton: UIButton!
    @IBOutlet weak var followbuttton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("dta: \(Following)")
        blockButtton.layer.cornerRadius = 12
        followbuttton.layer.cornerRadius = 12

    }
    
    func checkFollowing() {
        if Following == false {
            DispatchQueue.main.async {
                self.followbuttton.setTitle("Follow", for: .normal)
            }
        } else if Following == true {
            DispatchQueue.main.async {
                self.followbuttton.setTitle("Unfollow", for: .normal)
                print("unfollow")
            }
        }
    }
    func showErrorContactingServer() {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
