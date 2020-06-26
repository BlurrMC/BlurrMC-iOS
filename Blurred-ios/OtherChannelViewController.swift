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
    // Add peak function to dispaly video when peaking.
    @IBOutlet weak var collectionView: UICollectionView!
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    @IBOutlet weak var dropDownMenu: UIView!
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OtherChannelVideoCell", for: indexPath) as? OtherChannelVideoCell else { return UICollectionViewCell() }
        let Id: Int? = videos[indexPath.row].id
        
        cell.thumbnailView.image = UIImage(named: "load-image")
        
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(Id!).json").responseJSON { response in
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
                       self.showErrorContactingServer()
                   }
        }
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
                    self.showNoResponseFromServer()
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
                    self.showErrorContactingServer() // f
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
        let lineView = UIView(frame: CGRect(x: 0, y: 250, width: self.view.frame.size.width, height: 1))
        if traitCollection.userInterfaceStyle == .light {
            lineView.backgroundColor = UIColor.black
        } else {
            lineView.backgroundColor = UIColor.white
        }
        dropDownMenu.layer.borderWidth = 1
        dropDownMenu.layer.borderColor = UIColor.systemGray.cgColor
        dropDownMenu.layer.cornerRadius = 12
        dropDownMenu.removeFromSuperview()
        self.view.addSubview(lineView)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        self.avatarImage.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapppFunction))
        avatarImage.addGestureRecognizer(tappp)
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        channelVideoIds()
        self.avatarImage.contentScaleFactor = 1.5
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view != self.dropDownMenu
        { dropDownMenu.removeFromSuperview() }  /// Here you go bro here is the greek code to remove the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        dropDownMenu.removeFromSuperview()
        timer.invalidate()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadMemberChannel()
        channelVideoIds()
        timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
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
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    var doubleTap : Bool! = false
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        if (doubleTap) {
            doubleTap = false
            dropDownMenu.removeFromSuperview()
        } else {
            let userId: String?  = myValet.string(forKey: "Id")
            let userIdInt: Int? = Int(userId!)
            let userIdString: String = String("\(userIdInt)")
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
                            let username: Int? = parseJSON["id"] as? Int
                            let usernameId = String("\(username)")
                            if userIdString != usernameId {
                                DispatchQueue.main.async {
                                    self.view.addSubview(self.dropDownMenu)
                                }
                                self.doubleTap = true
                            } else {
                                self.pickAvatar()
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
        }
    }
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    func upload() {
        let token: String?  = self.tokenValet.string(forKey: "Token")
        let userId: String?  = self.myValet.string(forKey: "Id")
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            avatarImage.image = image
            upload()
        } else {
            self.showUnkownError()
        }
        self.dismiss(animated: true, completion: nil)
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
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
                                self.showNoResponseFromServer()
                            }
                            if followerCount != 0 {
                                DispatchQueue.main.async {
                                    self.followersLabel.text = "\(followerCount ?? 0)"
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.followersLabel.text = "0"
                                }
                            }
                            if followingCount != 0 {
                                DispatchQueue.main.async {
                                    self.followingLabel.text = "\(followingCount ?? 0)"
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.followingLabel.text = "0"
                                }
                            }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
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
                } else if segue.identifier == "showOtherVideoo" {
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
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showUnkownError() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "We don't know what happend wrong here! Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Fine", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
