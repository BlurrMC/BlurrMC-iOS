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
import Alamofire
import TTGSnackbar

class OtherFollowListViewController: UIViewController, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    // MARK: Prefetch Request
    func PreFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request("https://www.blurrmc.com/api/v1/channelsfollowing/\(followingVar)", method: .get, parameters: parameters, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                success(response)
            case .failure(let error):
                failure(error as NSError)
            }
            
        }
        
    }
    
    // MARK: Prefetch Rows
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if shouldBatchFetch == true {
            oldFollowCount = self.followings.count
            currentPage = currentPage + 1
            self.PreFetch(success: {(response) -> Void in
                guard let data = response?.data else {
                    print("error code: nt3qn847fr63ds, cheemsburbger") /// No please don't change it I like cheemsburbger
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedFollows = try decoder.decode(Followings.self, from: data)
                    if downloadedFollows.following.count < 50 {
                        self.shouldBatchFetch = false
                    }
                    self.followings.append(contentsOf: downloadedFollows.following)
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: indexPaths, with: .fade)
                    }
                } catch {
                    print("error code: asd8vh9348euwiadsjnkc, controller: following, error: \(error)")
                    return
                }
            }, failure: { (error) -> Void in
                print("error code: a9009duvf908u98rejdfadf")
                print(error as Any)
            })
        }
    }
    
    // MARK: Variables
    var followingVar = String()
    private var followings = [Following]()
    var userIsSelf = Bool()
    var currentPage: Int = 1
    var oldFollowCount = Int()
    var shouldBatchFetch = Bool()
    
    
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
        
        // Table
        self.tableView.dataSource = self
        self.tableView.prefetchDataSource = self
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
        let url = URL(string: "https://www.blurrmc.com/api/v1/channelsfollowing/\(Id).json")
        guard let downloadURL = url else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request(downloadURL, method: .get, parameters: parameters, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: asdf9h934qfewa")
                let snackbar = TTGSnackbar(message: "Error contacting server :O, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedFollows = try decoder.decode(Followings.self, from: data)
                if downloadedFollows.following.count < 50 {
                    self.shouldBatchFetch = false
                }
                self.followings = downloadedFollows.following
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                return
            }
        }
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
        let id: String
        init(username: String, name: String, id: String) {
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
        let Id: String = followings[indexPath.row].id
        let myUrl = URL(string: "https://www.blurrmc.com/api/v1/channels/\(Id).json")
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
                    guard let railsUrl = URL(string: "https://www.blurrmc.com\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
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
