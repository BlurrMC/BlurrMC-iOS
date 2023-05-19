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
import AlamofireImage
import TTGSnackbar

class ChannelViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    
    // MARK: Variables & Constants
    private var videos = [Video]()
    var documentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private let refreshControl = UIRefreshControl()
    let generator = UIImpactFeedbackGenerator(style: .light)
    var timesVideoReloaded = Int()
    var currentPage: Int = 1
    var oldVideoCount = Int()
    var shouldBatchFetch: Bool = true
    
    // MARK: Collectionview
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Prefetch Request
    func PreFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/channelvideos/\(userId)", method: .get, parameters: parameters, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                success(response)
            case .failure(let error):
                failure(error as NSError)
            }
            
        }
        
    }
    
    // MARK: Cancel prefetching
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Implement some kind of function here to cancel prefetching
    }
    
    // MARK: New rows for table node
    func insertNewRowsInTableNode(newVideos: [Video]) {
        if newVideos.count == 0 {
            return
        }
        let section = 0
        var indexPaths: [IndexPath] = []
        let total = self.videos.count + newVideos.count
        for item in self.videos.count...total-1 {
            let path = IndexPath(item: item, section: section)
            indexPaths.append(path)
        }
        self.videos.append(contentsOf: newVideos)
        if (oldVideoCount + newVideos.count) == self.videos.count {
            self.collectionView.insertItems(at: indexPaths)
        } else {
            return
        }
    }
    
    // MARK: Prefetching
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if shouldBatchFetch == true {
            oldVideoCount = self.videos.count
            currentPage = currentPage + 1
            self.PreFetch(success: {(response) -> Void in
                guard let data = response?.data else {
                    print("error code: 4129481234981241bcxb9afasdf")
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    if downloadedVideo.videos.count != 10 {
                        self.shouldBatchFetch = false
                    }
                    self.insertNewRowsInTableNode(newVideos: downloadedVideo.videos)
                } catch {
                    print("error code: 98asd098fuas9d8f234asdf, controller: channel, error: \(error)")
                    return
                }
            }, failure: { (error) -> Void in
                print("error code: asfoaisjdf322928414")
                print(error as Any)
            })
        }
        
    }
    
    // MARK: Cell for item at
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChannelVideoCell", for: indexPath) as? ChannelVideoCell else { return UICollectionViewCell() }
        //cell.layer.cornerRadius = 12
        //cell.layer.borderWidth = 1
        var resizedImageProcessors: [ImageProcessing] {
            let imageSize = CGSize(width: cell.thumbnailView.frame.width, height: cell.thumbnailView.frame.height)
            return [ImageProcessors.Resize(size: imageSize, contentMode: .aspectFill)]
        }
        let options = ImageLoadingOptions(
            placeholder: UIImage(named: "load-image"),
            transition: .fadeIn(duration: 0.25))
        AF.request("https://blurrmc.com/api/v1/videoinfo/\(videos[indexPath.row].videoid).json").responseJSON { response in
            var JSON: [String: Any]?
            guard let data = response.data else { return }
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let imageUrll = JSON!["thumbnail_url"] as? String else { return }
                let imageUrl = "https://blurrmc.com\(imageUrll)"
                guard let likenumber = JSON!["likecount"] as? Int else { return }
                switch likenumber {
                case _ where likenumber > 1000 && likenumber < 100000:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber/1000).\((likenumber/100)%10)k"
                    }
                case _ where likenumber > 100000 && likenumber < 1000000:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber/1000)k"
                    }
                case _ where likenumber > 1000000 && likenumber < 100000000:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber/1000000).\((likenumber/1000)%10)M"
                    }
                case _ where likenumber > 100000000:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber/1000000)M"
                    }
                case _ where likenumber == 1:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber)"
                    }
                default:
                    DispatchQueue.main.async {
                        cell.likeCount.text = "\(likenumber)"
                    }
                }
                guard let railsUrl = URL(string: imageUrl) else { return }
                let request = ImageRequest(
                  url: railsUrl,
                  processors: resizedImageProcessors)
                DispatchQueue.main.async {
                    Nuke.loadImage(with: request, options: options, into: cell.thumbnailView)
                }
            } catch {
                return
            }
        }
        
        return cell
    }
    
    
    // MARK: Did select row
    func collectionView(CollectionView: UICollectionView, didSelectRowAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        let destinationVC = ChannelVideoViewController()
        destinationVC.performSegue(withIdentifier: "showVideo", sender: self)
    }
    
    
    // MARK: Perform segue to video
    func seeVideo() {
        self.performSegue(withIdentifier: "showVideo", sender: self)
    }
    
    
    // MARK: Pass data through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        switch segue.destination {
        case is ChannelVideoViewController:
            let vc = segue.destination as? ChannelVideoViewController
            if segue.identifier == "showVideo" {
                if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                    let selectedRow = indexPath.row
                    vc?.videoString = videos[selectedRow].videoid
                    vc?.channelId = userId
                    vc?.rowNumber = indexPath.item
                    vc?.isItFromSearch = false
                }
            }
        case is OtherFollowerListViewController:
            let vc = segue.destination as? OtherFollowerListViewController
            vc?.followerVar = userId
            vc?.userIsSelf = true
        case is OtherFollowListViewController:
            let vc = segue.destination as? OtherFollowListViewController
            vc?.followingVar = userId
            vc?.userIsSelf = true
        default:
            break
        }
    }

    
    // MARK: Settings Button Action
    @IBAction func settingsButtonTap(_ sender: Any) {
        let settingsView =  self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        self.present(settingsView, animated: true, completion: nil)
    }

    
    // MARK: View did load
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Line view seperator
        let lineView = UIView()
        lineView.backgroundColor = UIColor.label
        
        // Gesture for labels
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshVideos(_:)), for: .valueChanged)
        self.view.addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        lineView.bottomAnchor.constraint(equalTo: self.collectionView.topAnchor, constant: 0).isActive = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.imageTapped(gesture:)))
        
        // UIImage improvments (i guess?)
        avatarImage.isUserInteractionEnabled = true
        ImageCache.shared.ttl = 120
        avatarImage.addGestureRecognizer(tapGesture)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tappFunction))
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        self.avatarImage.layer.cornerRadius = self.avatarImage.bounds.height / 2 /// how tall are you? oh, 6 foot. Then why the hell can't you stick to just being a perfect circle.
        
        
        // Channel + videos
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.isPrefetchingEnabled = true
        loadMemberChannel()
        channelVideoIds()
        generator.prepare()
        self.navigationItem.title = "My Channel"
    }
    
    // MARK: Video reload timer
    func videoReloadTimer(invalidate: Bool) {
        Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true, block: { timer in
            if invalidate == true {
                timer.invalidate()
            } else {
                self.channelVideoIds()
            }
        })
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.videoReloadTimer(invalidate: false)
    }
    
    
    // MARK: View will appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadMemberChannel()
        self.videoReloadTimer(invalidate: true)
        
    }
    
    
    // MARK: Refresh the videos
    @objc private func refreshVideos(_ sender: Any) {
        channelVideoIds()
        self.generator.impactOccurred()
    }
    
    
    // MARK: Avatar tapped
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            pickAvatar()
        }
    }
    
    
    // MARK: Follower Number Tap
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    
    
    // MARK: Following Number Tap
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    
    
    // MARK: Follower List Segue
    func goToFollowersList() {
        self.performSegue(withIdentifier: "showChannelFollowerList", sender: self)
    }
    
    
    // MARK: Following List Segue
    func goToFollowingList() {
        self.performSegue(withIdentifier: "showFollowList", sender: self)
    }
    
    
    // MARK: Channel Videos
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    
    class Video: Codable {
        let videoid: String
        init(videoid: String) {
            self.videoid = videoid
        }
    }
    

    // MARK: Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Load the channel's videos
    func channelVideoIds() {
        self.currentPage = 1
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let url = URL(string: "https://blurrmc.com/api/v1/channelvideos/\(userId)")
        guard let downloadURL = url else { return }
        AF.request(downloadURL, method: .get, parameters: parameters).responseJSON { response in
            guard let data = response.data else {
                print("error code: asdfasi9fasdf")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                self.videos = downloadedVideo.videos
                if self.videos.count != 10 {
                    self.shouldBatchFetch = false
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("error code: 1asdfasdfasf21341a, controller: channel, error: \(error)")
                return
            }
        }
    }
    
    
    // MARK: Load the channel's info
    func loadMemberChannel() {
        ImageCache.shared.costLimit = 1024 * 1024 * 100
        ImageCache.shared.countLimit = 100
        ImageCache.shared.ttl = 120
        guard let Id: String  = try? myValet.string(forKey: "Id") else { return }
        if let image = self.retrieveImage(forKey: "Avatar") {
            DispatchQueue.main.async {
                self.avatarImage.image = image
            }
        }
        let myUrl = URL(string: "https://blurrmc.com/api/v1/channels/\(Id).json")
            var request = URLRequest(url:myUrl!)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil {
                    let snackbar = TTGSnackbar(message: "Error contacting server, try again later. :(", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                    return
                } 
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    if let parseJSON = json {
                        let username: String? = parseJSON["username"] as? String
                        let name: String? = parseJSON["name"] as? String
                        let imageUrl: String? = parseJSON["avatar_url"] as? String
                        guard let followerCount: Int = parseJSON["followers_count"] as? Int else { return }
                        guard let followingCount: Int = parseJSON["following_count"] as? Int else { return }
                        let bio: String? = parseJSON["bio"] as? String 
                        guard let railsUrl = URL(string: "https://blurrmc.com\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else  { return }
                        if bio?.isEmpty != true {
                            DispatchQueue.main.async {
                                self.bioLabel.text = bio ?? ""
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.bioLabel.text = String(".") /// This is just for testing purposes, please change it in production
                            }
                            print("error code: 19vfana9as, issue: There is no bio")
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
                        AF.request(railsUrl).responseImage { response in
                            if case .success(let image) = response.result {
                                let preImage = image.af.imageScaled(to: CGSize(width: 30, height: 30))
                                let postImage = preImage.af.imageRounded(withCornerRadius: 15)
                                DispatchQueue.main.async {
                                    self.tabBarItem.image = postImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
                                    self.avatarImage.image = image
                                }
                                self.store(image: image, forKey: "Avatar")
                            }
                        }
                        try? self.myValet.setString("\(railsUrl)", forKey: "avatar url for \(Id)")
                    } else {
                        return
                    }
                } catch {
                        return
                }
            }
            task.resume()
    }
    
    
    // MARK: Load avatar for quicker access
    private func retrieveImage(forKey key: String) -> UIImage? {
        if let filePath = self.filePath(forKey: key),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData) {
            return image
        }
        print("error code: 0fmviq940ckc9rka93d")
        return nil
    }
    
    
    // MARK: Store avatar to be used for tab bar
    private func store(image: UIImage, forKey key: String) {
        if let pngRepresentation = image.pngData() {
            if let filePath = filePath(forKey: key) {
                do  {
                    try pngRepresentation.write(to: filePath, options: .atomic)
                } catch let err {
                    print("Saving file resulted in error: ", err)                
                }
            }
        }
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }

    
    // MARK: Import image for avatar
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true)
    }
    
    
    // MARK: Upload avatar image
    func upload() {
        guard let token: String  = try? self.tokenValet.string(forKey: "Token") else { return }
        guard let Id: String  = try? self.myValet.string(forKey: "Id") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let url = String("https://blurrmc.com/api/v1/registrations/\(Id)")
        let image = avatarImage.image///haha im small
        // let image = [UIImagePickerController.InfoKey.editedImage]
        guard let imgcompressed = image!.jpegData(compressionQuality: 0.5) else { return }
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imgcompressed, withName: "avatar" , fileName: "\(Id)-avatar.png", mimeType: "image/png")
        },
            to: url, method: .patch , headers: headers)
            .response { resp in
                print(resp)


        }
    }
    
    
    // MARK: Image Picker Controler
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            avatarImage.image = image
            let preImage = image.resize(targetSize: CGSize(width: 30, height: 30))
            let postImage = preImage.af.imageRounded(withCornerRadius: 15)
            self.tabBarItem.image = postImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
            upload()
            self.store(image: image, forKey: "Avatar")
        } 
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Get Document Directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    // MARK: Take picture for avatar
    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    
    // MARK: Pick Avatar Alert
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
        self.generator.impactOccurred()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
