//
//  ChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke
import Alamofire

class ChannelViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDataSource { // Look at youself. Look at what you have done.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChannelVideoCell", for: indexPath) as? ChannelVideoCell else { return UICollectionViewCell() }
        let Id: Int? = videos[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(Id!).json")
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
                    let imageUrl: String? = parseJSON["thumbnail_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl!)")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.thumbnailView)
                    }
                } else {
                    self.showErrorContactingServer()
                }
            } catch {
                self.showNoResponseFromServer()
                print(error)
                }
        }
        task.resume()
        return cell
    }
    func seeVideo() {
        self.performSegue(withIdentifier: "showVideo", sender: self)
    }
    func collectionView(CollectionView: UICollectionView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = ChannelVideoViewController()
        destinationVC.performSegue(withIdentifier: "showVideo", sender: self)
    }
    @IBOutlet weak var collectionView: UICollectionView!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is ChannelVideoViewController
        {
            if let vc = segue.destination as? ChannelVideoViewController {
                if segue.identifier == "showVideo" {
                    if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                        let selectedRow = indexPath.row
                        vc.videoString = videos[selectedRow].id
                    }
                }
            } else {
                self.showErrorContactingServer()
            }
        }
    }
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    var timer = Timer()
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    @IBAction func settingsButtonTap(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let lineView = UIView(frame: CGRect(x: 0, y: 265, width: self.view.frame.size.width, height: 1))
        if traitCollection.userInterfaceStyle == .light {
            lineView.backgroundColor = UIColor.black
        } else {
            lineView.backgroundColor = UIColor.white
        }
        self.view.addSubview(lineView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.imageTapped(gesture:)))
        avatarImage.isUserInteractionEnabled = true
        avatarImage.addGestureRecognizer(tapGesture)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tappFunction))
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        channelVideoIds()
        self.avatarImage.contentScaleFactor = 1.5
        // Setup the view so you can integerate it right away with the channel api.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadMemberChannel()
        channelVideoIds()
        timer = Timer.scheduledTimer(timeInterval: 40.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
    }
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            pickAvatar()
        }
    }
    @objc func timerAction() {
        if myValet.string(forKey: "Id") == nil {
            self.timer.invalidate()
        } else {
            loadMemberChannel()
            channelVideoIds()
        }
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    func goToFollowersList() {
        let followersListPage = self.storyboard?.instantiateViewController(identifier: "FollowerListViewController") as! FollowerListViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = followersListPage
        self.present(followersListPage, animated:true, completion:nil)
    }
    func goToFollowingList() {
        let followeringListPage = self.storyboard?.instantiateViewController(identifier: "FollowListViewController") as! FollowListViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = followeringListPage
        self.present(followeringListPage, animated:true, completion:nil)
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
        let userId: String?  = myValet.string(forKey: "Id")
        let Id = Int(userId!)
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")  // 23:40
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
    func loadMemberChannel() {
        let userId: String?  = myValet.string(forKey: "Id")
        let Id = Int(userId!)
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
                    let username: String? = parseJSON["username"] as? String
                    let name: String? = parseJSON["name"] as? String
                    let imageUrl: String? = parseJSON["avatar_url"] as? String
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
                }
            } catch {
                    self.showNoResponseFromServer()
                }
        }
        task.resume()
    } // I will set this up later
    
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
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

    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    func showErrorContactingServer() {

        // create the alert
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
}
