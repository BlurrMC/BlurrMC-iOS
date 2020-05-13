//
//  FollowerListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/9/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Nuke

class FollowerListViewController: UIViewController, UITableViewDataSource {
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    private var followers = [Follower]()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()
        tableView.tableFooterView = UIView()

        // Do any additional setup after loading the view.
    }
    func downloadJson() { // Still not done we need to add the user's butt image
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
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
                DispatchQueue.main.async {
                    self.showErrorContactingServer() // f
                }
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
        let name: String
        let id: Int
        init(username: String, name: String, id: Int) {
            self.username = username
            self.name = name
            self.id = id
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerCell") as? FollowerCell else { return UITableViewCell() }
        cell.followerUsername.text = followers[indexPath.row].username // Hey stupid if you want to add more just add one more line of code here
        cell.followerName.text = followers[indexPath.row].name
        let Id: Int? = followers[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showErrorContactingServer()
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let imageUrl: String? = parseJSON["image_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.followerAvatar)
                        }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer()
                    }
                    print(error ?? "No error")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
                print(error)
                }
        }
        task.resume()
        return cell
    }
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
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
