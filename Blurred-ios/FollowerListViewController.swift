//
//  FollowerListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/4/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class FollowerListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        parseFollowers()
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        tableView.dataSource = self;
        let follower = followers[indexPath.row]
        cell.textLabel!.text = follower.username
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        return cell

    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        parseFollowers()

        // Do any additional setup after loading the view.
    }
    struct Root: Codable {
        let followers : FollowerData
    }
    struct FollowerData: Codable {
        enum CodingKeys: String, CodingKey {
            case username = "username"
        }
        let username : String
    }
    @IBOutlet weak var tableView: UITableView!
    var followers = [FollowerData]()
    func parseFollowers() {
        let decoder = JSONDecoder()
        do {
            let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
            let url =  URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json")
            let jsonData = NSData(contentsOf: url!)
            let output = try decoder.decode(Root.self, from: jsonData! as Data)
        } catch {
            print(error.localizedDescription)
            showNoResponseFromServer()
            return
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    // func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //   return followers.count
    // }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
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
