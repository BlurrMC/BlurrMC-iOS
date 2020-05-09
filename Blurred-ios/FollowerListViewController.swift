//
//  FollowerListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/9/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class FollowerListViewController: UIViewController, UITableViewDataSource {
    
    private var followers = [Follower]()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()

        // Do any additional setup after loading the view.
    }
    func downloadJson() {
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json")
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                print("uh oh")
                return
            }
            print("I got the data")
            do {
                let decoder = JSONDecoder()
                let downloadedFollower = try decoder.decode(Followers.self, from: data)
                self.followers = downloadedFollower.followers
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("You have no followers go die.")
            }
        }.resume()
    }
    class Followers: Codable {
        let followers: [Follower]
        init(followers: [Follower]) {
            self.followers = followers
        }
    }
    class Follower: Codable {
        let username: String
        init(username: String) {
            self.username = username
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerCell") as? FollowerCell else { return UITableViewCell() }
        cell.followerUsername.text = followers[indexPath.row].username // Hey stupid if you want to add more just add one more line of code here
        return cell
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
