//
//  OtherChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Nuke
import Valet
import Foundation

class OtherChannelViewController: UIViewController, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    @IBOutlet weak var dropDownMenu: UIView!
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OtherChannelVideoCell", for: indexPath) as? OtherChannelVideoCell else { return UICollectionViewCell() }
        let Id: Int? = videos[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(Id!).json")
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
                    let imageUrl: String? = parseJSON["thumbnail_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl!)")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.thumbnailView)
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
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    class Video: Codable {
        let id: Int
        init(username: String, name: String, id: Int) {
            self.id = id // Pass id through a seuge to channelvideo
        }
    }
    private var videos = [Video]()
    func channelVideoIds() { // Still not done we need to add the user's butt image
        if chanelVar != nil {
            let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(chanelVar).json")  // 23:40
            guard let downloadURL = url else { return }
            URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
                guard let data = data, error == nil, urlResponse != nil else {
                    DispatchQueue.main.async {
                        self.showNoResponseFromServer()
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    self.videos = downloadedVideo.videos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer() // f
                    }
                }
            }.resume()
        } else if channelVar != nil {
            let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(channelVar).json")  // 23:40
            guard let downloadURL = url else { return }
            URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
                guard let data = data, error == nil, urlResponse != nil else {
                    DispatchQueue.main.async {
                        self.showNoResponseFromServer()
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    self.videos = downloadedVideo.videos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer() // f
                    }
                }
            }.resume()
        }
        
    }
    var chanelVar = String()
    var channelVar = String() // Remove all channelVar methods (it's not in use)
    var timer = Timer()
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let lineView = UIView(frame: CGRect(x: 0, y: 265, width: self.view.frame.size.width, height: 1))
        if traitCollection.userInterfaceStyle == .light {
            lineView.backgroundColor = UIColor.black
        } else {
            lineView.backgroundColor = UIColor.white
        }
        dropDownMenu.layer.borderWidth = 1
        dropDownMenu.layer.borderColor = UIColor.systemGray.cgColor
        dropDownMenu.layer.cornerRadius = 12
        
        self.view.addSubview(lineView)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tappFunction))
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        channelVideoIds()
        self.avatarImage.contentScaleFactor = 1.5
        

        // Do any additional setup after loading the view.
    }
    func viewWillAppear() {
        super.viewWillAppear(true)
        loadMemberChannel()
        channelVideoIds()
        timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    func viewWillDisappear() {
        super.viewWillDisappear(true)
        timer.invalidate()
    }
    @objc func timerAction() {
        if myValet.string(forKey: "Id") == nil {
            self.timer.invalidate()
        } else {
            loadMemberChannel()
            channelVideoIds()
        }
        if chanelVar == nil {
            self.timer.invalidate()
        } else {
            loadMemberChannel()
        }
        print("timer activated")
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        print("tap working")
        goToFollowersList()
    }
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    func goToFollowersList() {
        self.performSegue(withIdentifier: "showOtherFollower", sender: self)
    }
    func goToFollowingList() {
        self.performSegue(withIdentifier: "showOtherFollowing", sender: self)
    }
    var channelUsername = String()
    func loadMemberChannel() {
        if chanelVar != nil {
            let Id = chanelVar
            let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id).json")
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
                        let username: String? = parseJSON["username"] as? String
                        self.channelUsername = username!
                        let name: String? = parseJSON["name"] as? String
                        let imageUrl: String? = parseJSON["avatar_url"] as? String // Forgot to change to the new api here
                        let followerCount: Int? = parseJSON["followers_count"] as? Int
                        let followingCount: Int? = parseJSON["following_count"] as? Int
                        let bio: String? = parseJSON["bio"] as? String
                        let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                        DispatchQueue.main.async {
                            if bio?.isEmpty != true {
                                self.bioLabel.text = bio ?? ""
                            } else {
                                self.bioLabel.text = String("")
                            }
                            if username?.isEmpty != true && name?.isEmpty != true {
                                self.usernameLabel.text = username ?? ""
                                self.nameLabel.text = name ?? ""
                            } else {
                                self.showNoResponseFromServer()
                            }
                            print(followerCount ?? "none")
                            if followerCount != 0 {
                                self.followersLabel.text = "\(followerCount ?? 0)"
                            } else {
                                self.followersLabel.text = "0"
                            }
                            if followingCount != 0 {
                                self.followingLabel.text = "\(followingCount ?? 0)"
                            } else {
                                self.followingLabel.text = "0"
                            }
                            Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
                            }
                    } else {
                        self.showErrorContactingServer()
                        print(error ?? "No error")
                    }
                } catch {
                        self.showNoResponseFromServer()
                        print(error)
                    }
            }
            task.resume()
        } else if channelVar != nil {
            let Id = channelVar
            let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id).json")
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
                        let username: String? = parseJSON["username"] as? String
                        let name: String? = parseJSON["name"] as? String
                        let imageUrl: String? = parseJSON["avatar_url"] as? String
                        let followerCount: Int? = parseJSON["followers_count"] as? Int
                        let followingCount: Int? = parseJSON["following_count"] as? Int
                        let bio: String? = parseJSON["bio"] as? String
                        let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                        DispatchQueue.main.async {
                            if bio?.isEmpty != true {
                                self.bioLabel.text = bio!
                            } else {
                                self.bioLabel.text = String("")
                            }
                            if username?.isEmpty != true && name?.isEmpty != true {
                                self.usernameLabel.text = username!
                                self.nameLabel.text = name!
                            } else {
                                self.showNoResponseFromServer()
                            }
                            print(followerCount ?? "none")
                            if followerCount != 0 {
                                self.followersLabel.text = "\(followerCount ?? 0)"
                            } else {
                                self.followersLabel.text = "0"
                            }
                            if followingCount != 0 {
                                self.followingLabel.text = "\(followingCount ?? 0)"
                            } else {
                                self.followingLabel.text = "0"
                            }
                            Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
                            }
                    } else {
                        self.showErrorContactingServer()
                        print(error ?? "No error")
                    }
                } catch {
                        self.showNoResponseFromServer()
                        print(error)
                    }
            }
            task.resume()

        }
            } // I will set this up later
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is OtherFollowerListViewController
        {
            if let vc = segue.destination as? OtherFollowerListViewController {
                if segue.identifier == "showOtherFollower" {
                    vc.followerVar = channelUsername
                }
            } else {
                self.showErrorContactingServer()
            }
        } else if segue.destination is OtherFollowListViewController {
            if let vc = segue.destination as? OtherFollowListViewController {
                if segue.identifier == "showOtherFollowing" {
                    vc.followingVar = channelUsername
                }
            }
        } else if segue.destination is ChannelVideoViewController {
            if let vc = segue.destination as? ChannelVideoViewController {
                if segue.identifier == "showOtherVideo" {
                    if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                        let selectedRow = indexPath.row
                        vc.videoString = videos[selectedRow].id
                    }
                }
            } else {
                self.showUnkownError()
            }
        }
    }
    func showErrorContactingServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showUnkownError() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "We don't know what happend wrong here! Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Fine", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
}
