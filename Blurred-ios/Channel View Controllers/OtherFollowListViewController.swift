//
//  OtherFollowListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke

class OtherFollowListViewController: UIViewController, UITableViewDataSource {
    var followingVar = String()
    private var followings = [Following]()
    @IBOutlet weak var nothingHere: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    private let refreshControl = UIRefreshControl()
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshFollowing(_:)), for: .valueChanged)
        tableView.tableFooterView = UIView()
        // Do any additional setup after loading the view.
    }
    @objc private func refreshFollowing(_ sender: Any) {
        downloadJson()
    }

    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        downloadJson()
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    // MARK: Get the user's followings
    func downloadJson() { 
        let Id = followingVar
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelsfollowing/\(Id).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                self.showNoResponseFromServer()
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedFollowing = try decoder.decode(Followings.self, from: data)
                self.followings = downloadedFollowing.following
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print(error)
            }
        }.resume()
    }
    class Followings: Codable {
        let following: [Following]
        init(following: [Following]) {
            self.following = following
        }
    }
    class Following: Codable {
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
        return followings.count
    }
    func tableView(tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = OtherChannelViewController()
        destinationVC.performSegue(withIdentifier: "showChannel", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            let detailVC = segue.destination as! OtherChannelViewController
            detailVC.chanelVar = followings[selectedRow].username
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OtherFollowingCell") as? OtherFollowingCell else { return UITableViewCell() }
        cell.followingUsername.text = followings[indexPath.row].username // Hey stupid if you want to add more just add one more line of code here
        cell.followingName.text = followings[indexPath.row].name
            if cell.followingUsername.text == nil {
                DispatchQueue.main.async {
                    self.nothingHere.text = String("Nothing Here")
                }
            } else {
                DispatchQueue.main.async {
                     self.nothingHere.text = String("")
                }
            }
        let Id: Int? = followings[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.showErrorContactingServer()
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let imageUrl: String? = parseJSON["avatar_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.followingAvatar)
                    }
                } else {
                    self.showErrorContactingServer()
                    print(error ?? "")
                }
            } catch {
                self.showNoResponseFromServer()
                print(error)
                }
        }
        task.resume()
        return cell
    }
    func showErrorContactingServer() {
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showNoResponseFromServer() {
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
