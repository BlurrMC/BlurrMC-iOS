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
import Alamofire

class OtherChannelViewController: UIViewController, UICollectionViewDataSource, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    // MARK: Variables
    var isItThemselves = Bool()
    private var videos = [Video]()
    var chanelVar = String()
    var following = Bool()
    var relationshipId = Int()
    var channelUsername = String()
    var timer2 = Timer()
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Outlets
    @IBOutlet var dropDownButtons: [UIButton]!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    
    
    // MARK: Lets
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: Number Of Items In Section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    
    // MARK: Checks the user if they are viewing themselves (dropdown menu).
    func checkIfOtherUserIsCurrentUser() {
        let userId: String?  = try? myValet.string(forKey: "Id")
        let userIdInt: Int? = Int(userId!)
        let userIdString: String = String("\(userIdInt)")
        let Id = chanelVar
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print(error as Any)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let username: Int? = parseJSON["id"] as? Int
                    let usernameId = String("\(username)")
                    if userIdString != usernameId {
                        self.isItThemselves = false
                    } else {
                        self.isItThemselves = true
                    }
                } else {
                    print(error ?? "")
                    return
                }
            } catch {
                print(error)
                return
            }
        }
    task.resume()
    }
    
    
    // MARK: Did Select Row
    func collectionView(CollectionView: UICollectionView, didSelectRowAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        let destinationVC = ChannelVideoViewController()
        destinationVC.performSegue(withIdentifier: "showVideo", sender: self)
    }

    
    // MARK: Follow Button Tap
    @IBAction func followButtonTap(_ sender: Any) {
        following = !following
        switch following {
        case true:
            DispatchQueue.main.async {
                self.followButton.setTitle("Unfollow", for: .normal)
            }
            // Follow the targeted user
            followUser()
        case false:
            DispatchQueue.main.async {
                self.followButton.setTitle("Follow", for: .normal)
            }
            // Unfollow the targeted user
            unfollowUser()
        }
    }
    
    
    // MARK: Block Button Tap
    @IBAction func blockButtonTap(_ sender: Any) {
    }
    

    // MARK: Cell For Item At
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OtherChannelVideoCell", for: indexPath) as? OtherChannelVideoCell else { return UICollectionViewCell() }
        let Id: Int? = videos[indexPath.row].id
        
        cell.thumbnailView.image = UIImage(named: "load-image")
        AF.request("http://10.0.0.2:3000/api/v1/videoinfo/\(Id!).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let imageUrl = JSON!["thumbnail_url"] as? String
                let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl!)")
                guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {
                    return
                }
                DispatchQueue.main.async {
                    Nuke.loadImage(with: railsUrl ?? imageURL, into: cell.thumbnailView)
                }
            } catch {
                return
            }
        }
        return cell
    }
    
    
    // MARK: Videos info downloaded
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    
    class Video: Codable {
        let id: Int
        init(username: String, name: String, id: Int) {
            self.id = id
        }
    }
    
    
    // MARK: Load the channel's videos
    func channelVideoIds() { // Still not done we need to add the user's butt image
            let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(chanelVar).json")  // 23:40
            guard let downloadURL = url else { return }
            URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
                guard let data = data, error == nil, urlResponse != nil else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    self.videos = downloadedVideo.videos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } catch {
                    return
                }
            }.resume()
    }
    
    
    // MARK: Back Button Function
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        ImageCache.shared.ttl = 120
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshVideos(_:)), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapppFunction))
        avatarImage.addGestureRecognizer(tappp)
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        channelVideoIds()
        let lineView = UIView(frame: CGRect(x: 0, y: 240, width: self.view.frame.size.width, height: 1  ))
        if traitCollection.userInterfaceStyle == .light {
            lineView.backgroundColor = UIColor.black
        } else {
            lineView.backgroundColor = UIColor.white
        }
        self.avatarImage.contentScaleFactor = 1.5
    }
    
    
    // MARK: Refresh Videos Refresh
    @objc private func refreshVideos(_ sender: Any) {
        channelVideoIds()
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        dropDownButtons.forEach { (button) in
            if button.isHidden == false {
                button.isHidden = true
            }
        }
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadMemberChannel()
        channelVideoIds()
        checkForFollowing()
        checkIfOtherUserIsCurrentUser()
    }
    
    
    // MARK: Follower Tap Function
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    
    
    // MARK: Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Dropdown menu tap function
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        if isItThemselves == false {
            // Check if user is following before showing the follow/block button.
            switch following {
                case true:
                    DispatchQueue.main.async {
                        self.followButton.setTitle("Unfollow", for: .normal)
                    }
                case false:
                    DispatchQueue.main.async {
                        self.followButton.setTitle("Follow", for: .normal)
                    }
                }
                dropDownButtons.forEach { (button) in
                    UIView.animate(withDuration: 0.15, animations: {
                        button.isHidden = !button.isHidden
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                    
                }
        } else {
            self.pickAvatar()
        }
        
    }
    
    
    // MARK: Unfollow the user
    func unfollowUser() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let params = [
            "username": "\(chanelVar)"
        ] as [String: String]
        let url = String("http://10.0.0.2:3000/api/v1/apirelationships/\(relationshipId)")
        AF.request(URL.init(string: url)!, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status == "User unfollowed" {
                    self.following = false
                } else {
                    return
                }
            } catch {
                print("error code: 1039574638")
                return
            }
            }
    }
    
    
    // MARK: Follow the user
    func followUser() {
        let accessToken: String? = try? tokenValet.string(forKey: "Token")
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/apirelationships/")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        let params = ["id": "\(chanelVar)"] as [String: String]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch {
            print("error code: 1adnf94k392b")
            return
        }
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print("error code: 12fue971j")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let status: String? = parseJSON["status"] as? String
                    let relationshipId: Int? = parseJSON["relationship_id"] as? Int
                    if status == "User Followed" {
                        self.following = true
                        self.relationshipId = relationshipId!
                    } else {
                        self.following = false
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
    
    
    // MARK: Check if user is following/blocking (for dropdown)
    func checkForFollowing() {
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
                                let relationshipId: Int? = parseJSON["relationship_id"] as? Int
                                DispatchQueue.main.async {
                                    if status == "User is not following." {
                                        self.following = false
                                    } else if status == "User is following." {
                                        self.following = true
                                        self.relationshipId = relationshipId!
                                    } else {
                                        print("error code: afnadf8y3")
                                        return
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
    
    
    // MARK: Import images for changing avatar
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    
    
    // MARK: Take picture for changing avatar
    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    
    
    // MARK: Upload changed avatar
    func upload() {
        let token: String?  = try? self.tokenValet.string(forKey: "Token")
        let userId: String?  = try? self.myValet.string(forKey: "Id")
        let Id = Int(userId!)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/registrations/\(Id!)")
        let image = avatarImage.image///haha im small
        // let image = [UIImagePickerController.InfoKey.editedImage]
        guard let imgcompressed = image!.jpegData(compressionQuality: 0.5) else { return }
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imgcompressed, withName: "avatar" , fileName: "\(Id!)-avatar.png", mimeType: "image/png")
        },
            to: url, method: .patch , headers: headers)
            .response { resp in
                print(resp)


        }
    }
    
    
    // MARK: Image Picker Controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            avatarImage.image = image
            upload()
        } else {
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Documents Directory (For Images)
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    // MARK: Pick Avatar
    func pickAvatar() {
            let alert = UIAlertController(title: "Avatar", message: "Change your avatar.", preferredStyle: UIAlertController.Style.actionSheet)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "Pick from gallery", style: UIAlertAction.Style.default, handler: { action in
                print("Pick from gallery")
                self.importImage()
            }))
            alert.addAction(UIAlertAction(title: "Take photo", style: UIAlertAction.Style.default, handler: { action in
                print("Take photo")
                self.takePicture()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Following Tap Function
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    
    
    // MARK: Follower List Segue
    func goToFollowersList() {
        self.performSegue(withIdentifier: "showOtherFollower", sender: self)
    }
    
    
    // MARK: Following List Segue
    func goToFollowingList() {
        self.performSegue(withIdentifier: "showOtherFollowing", sender: self)
    }
    

    // MARK: Load the channel's information
    func loadMemberChannel() {
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
                        guard let followerCount: Int = parseJSON["followers_count"] as? Int else { return }
                        guard let followingCount: Int = parseJSON["following_count"] as? Int else { return }
                        let bio: String? = parseJSON["bio"] as? String
                        let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                            if bio?.isEmpty != true {
                                DispatchQueue.main.async {
                                    self.bioLabel.text = bio ?? ""
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.bioLabel.text = String("")
                                }
                            }
                            if username?.isEmpty != true && name?.isEmpty != true {
                                DispatchQueue.main.async {
                                    self.usernameLabel.text = username ?? ""
                                    self.nameLabel.text = name ?? ""
                                }
                            } else {
                                return
                            }
                        switch followerCount {
                        case _ where followerCount < 1000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount)"
                            }
                        case _ where followerCount > 1000 && followerCount < 100000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000).\((followerCount/100)%10)k" }
                        case _ where followerCount > 100000 && followerCount < 1000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000)k"
                            }
                        case _ where followerCount > 1000000 && followerCount < 100000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000000).\((followerCount/1000)%10)M"
                            }
                        case _ where followerCount > 100000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000000)M"
                            }
                        default:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount )"
                            }
                        }
                        switch followingCount {
                        case _ where followingCount < 1000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount)"
                            }
                        case _ where followingCount > 1000 && followingCount < 100000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000).\((followingCount/100)%10)k" }
                        case _ where followingCount > 100000 && followingCount < 1000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000)k"
                            }
                        case _ where followingCount > 1000000 && followingCount < 100000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000000).\((followingCount/1000)%10)M"
                            }
                        case _ where followingCount > 100000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000000)M"
                            }
                        default:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount)"
                            }
                        }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
                        }
                    } else {
                        print(error ?? "")
                        return
                    }
                } catch {
                        print(error)
                    return
                }
            }
        task.resume()
    }
    
    
    // MARK: Touch End For Dropdown
    func touchesEnded(touches: NSSet, withEvent event: UIEvent)
    {
        super.touchesEnded(touches as! Set<UITouch>, with: event)
        dismissView()
    }
    
    
    // MARK: Dismiss The Dropdown
    func dismissView() {
        if followButton.isHidden == false && blockButton.isHidden == false {
            if isItThemselves == false {
                    dropDownButtons.forEach { (button) in
                        UIView.animate(withDuration: 0.15, animations: {
                            button.isHidden = !button.isHidden
                            self.view.layoutIfNeeded()
                        }, completion: nil)
                        
                    }
            }
            
        }
        self.view.gestureRecognizers?.forEach(view.removeGestureRecognizer)
    }
    
    
    // MARK: Segue Info
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is OtherFollowerListViewController
        {
            if let vc = segue.destination as? OtherFollowerListViewController {
                if segue.identifier == "showOtherFollower" {
                    vc.followerVar = channelUsername
                }
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
                        vc.channelId = chanelVar
                        vc.rowNumber = indexPath.item
                        vc.isItFromSearch = false
                    }
                } else if segue.identifier == "showOtherVideoo" {
                    if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                        let selectedRow = indexPath.row
                        vc.videoString = videos[selectedRow].id
                    }
                }
            }
        }
    }
    
    
    // MARK: Error Contacting Server Alert
    func showErrorContactingServer() {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
