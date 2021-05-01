//
//  OtherFollowListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//
// This could probably get merged with otherfollowerlist (or vice versa) and add a bool or something to switch between follower and following.

import UIKit
import Valet
import Nuke

class OtherFollowListViewController: UIViewController, UITableViewDataSource {
    
    // MARK: Variables
    var followingVar = String()
    private var followings = [Following]()
    var userIsSelf = Bool()
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Outlets
    @IBOutlet weak var nothingHere: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: Lets
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: Back Button Tap
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshFollowing(_:)), for: .valueChanged)
        tableView.tableFooterView = UIView()
        let contentModes = ImageLoadingOptions.ContentModes(
          success: .scaleAspectFill,
          failure: .scaleAspectFill,
          placeholder: .scaleAspectFill)
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = UIImage(named: "load-image")
        ImageLoadingOptions.shared.failureImage = UIImage(named: "load-image")
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.25)
        DataLoader.sharedUrlCache.diskCapacity = 0
        switch userIsSelf {
        case true:
            self.navigationItem.title = "Following"
        case false:
            self.navigationItem.title = "@" + self.followingVar + "'s Follows"
        }
        // Colors
        if traitCollection.userInterfaceStyle == .light {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }
    
    
    // MARK: Refresh Following
    @objc private func refreshFollowing(_ sender: Any) {
        downloadJson()
    }
    
    
    // MARK: Did Receive Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        downloadJson()
    }
    
    
    // MARK: Get the user's followings
    func downloadJson() { 
        let Id = followingVar
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelsfollowing/\(Id).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
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
    
    
    // MARK: Following Info From JSON
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
    
    
    // MARK: # Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followings.count
    }
    
    
    // MARK: Did Select Row At
    func tableView(tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OtherFollowingCell else { return }
        let destinationVC = OtherChannelViewController()
        destinationVC.segueName = self.followings[indexPath.row].name
        destinationVC.segueUsername = self.followings[indexPath.row].username
        destinationVC.isReported = cell.isReported
        destinationVC.avatarUrl = cell.avatarUrl
        destinationVC.performSegue(withIdentifier: "showChannel", sender: self)
    }
    
    
    // MARK: Cell For Row At
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
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let imageUrl: String? = parseJSON["avatar_url"] as? String
                    guard let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.followingAvatar)
                    }
                    guard let isReported = parseJSON["reported"] as? Bool else { return }
                    cell.isReported = isReported
                    cell.avatarUrl = railsUrl.absoluteString
                } else {
                    print(error ?? "error code: a9gnaids8723hdas78h8")
                }
            } catch {
                print(error)
                return
            }
        }
        task.resume()
        return cell
    }
    
    
    // MARK: Pass Info Through Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            let detailVC = segue.destination as! OtherChannelViewController
            detailVC.chanelVar = followings[selectedRow].username
        }
    }
    
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
