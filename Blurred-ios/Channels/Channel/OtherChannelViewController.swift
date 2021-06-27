//
//  OtherChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//
// This controller should probably get merged with ChannelViewController, honestly pretty dumb, but I don't currently have the time to merge this crap.

import UIKit
import Nuke
import Valet
import Foundation
import Alamofire
import Combine
import TTGSnackbar

class OtherChannelViewController: UIViewController, UICollectionViewDataSource, UIImagePickerControllerDelegate & UINavigationControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    // MARK: Variables & Constants
    var isItThemselves = Bool()
    private var videos = [Video]()
    var chanelVar = String() // This is the channel's id
    // Explainer for why it's called chanel var:
    /// This view controller was made very early on in the development process (when I didn't know much) and I had two variables for the channel's id. One was called channelVar and the other (this one) was called chanelVar.
    /// As I got more experience developing I realised that using two different variables made it very confusing, so I removed the one being used the least (which was channelVar). From that day on, I haven't
    /// changed the variable name since I'm worried that it's gonna cause a chain of issues.
    var following = Bool()
    var blocking = Bool()
    var relationshipId = String()
    var channelUsername = String()
    var timer2 = Timer()
    var blockId = String()
    var isReported = Bool()
    var cancellable: AnyCancellable?
    var resizedImageProcessors: [ImageProcessing] = []
    var avatarUrl: String?
    var segueUsername: String?
    var segueName: String?
    var segueFollowerCount: String?
    var segueBio: String?
    var timesReload = Int()
    var currentPage: Int = 1
    var oldVideoCount = Int()
    var shouldBatchFetch: Bool = true
    private let refreshControl = UIRefreshControl()
    let followGenerator = UIImpactFeedbackGenerator(style: .light)
    let blockGenerator = UIImpactFeedbackGenerator(style: .medium) // Medium since you did something SERIOUS...
    // BLOCK SOMEONE!!!!!!
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Outlets
    @IBOutlet var dropDownButtons: [UIButton]!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var userBlockedLabel: UILabel!
    @IBOutlet weak var dropDownStack: UIStackView!
    
    
    // MARK: Prefetch Request
    func PreFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channelvideos/\(chanelVar)", method: .get, parameters: parameters, headers: headers).responseJSON { response in
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
    
    // MARK: Prefetching
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if shouldBatchFetch == true {
            oldVideoCount = self.videos.count
            currentPage = currentPage + 1
            self.PreFetch(success: {(response) -> Void in
                guard let data = response?.data else {
                    print("error code: 90129fghcmoa93441haga8sd78") // This printing of error code: go0f0urself0finding0the0error system is actually getting really stupid
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    if downloadedVideo.videos.count < 10 {
                        self.shouldBatchFetch = false
                    }
                    self.videos.append(contentsOf: downloadedVideo.videos)
                    DispatchQueue.main.async {
                        self.collectionView.reloadItems(at: indexPaths)
                    }
                } catch {
                    print("error code: aifosdfasdf14czxcvbbnsdfg, controller: otherchannel, error: \(error)")
                    return
                }
            }, failure: { (error) -> Void in
                print("error code: 2r839b7twaefsdzxvcvt3498werfs")
                print(error as Any)
            })
        }
        
    }
    
    
    // MARK: Number Of Items In Section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    
    // MARK: Load any info from segue info
    func loadSegueInfo() {
        self.nameLabel.text = segueName
        self.usernameLabel.text = segueUsername
        self.bioLabel.text = segueBio
        if self.segueFollowerCount != nil {
            self.followersLabel.text = self.segueFollowerCount
        }
    }
    
    
    // MARK: Checks if user is themselves (dropdown menu).
    func checkIfOtherUserIsCurrentUser() {
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        let Id = chanelVar
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(Id).json")
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
                    let username: String? = parseJSON["id"] as? String
                    if userId != username {
                        self.isItThemselves = false
                    } else {
                        self.isItThemselves = true
                    }
                } else {
                    print(error ?? "no error but somehow error")
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
        self.followGenerator.impactOccurred()
        let throttler = Throttler(minimumDelay: 3)
        following = !following
        switch following {
        case true:
            DispatchQueue.main.async {
                self.followButton.setTitle("Unfollow", for: .normal)
            }
            throttler.throttle( {
                self.followUser()
            }, uniqueId: nil)
        case false:
            DispatchQueue.main.async {
                self.followButton.setTitle("Follow", for: .normal)
            }
            throttler.throttle( {
                self.unfollowUser()
            }, uniqueId: nil)
        }
    }
    
    
    // MARK: Report Button Tapped
    @IBAction func reportButtonTap(_ sender: Any) {
        if isReported != true {
            self.isReported = true
            dropDownButtons.forEach { (button) in
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = !button.isHidden
                    
                    self.view.layoutIfNeeded()
                }, completion: {_ in
                    self.reportButton.removeFromSuperview()
                })
                
            }
            reportUser()
        }
    }
    
    
    // MARK: Report the user
    func reportUser() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let params = [
            "c_id": chanelVar
        ]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/reports")
        AF.request(URL.init(string: url)!, method: .post, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let response = response.data else {
                print("error code: asdfh239urqhiewadjsnafsd")
                return
            }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Reported" {
                    print("error code: amcir2bauinfs")
                }
            } catch {
                print(error)
                print("error code: cadskam329dj29")
                return
            }
        }
    }
    
    
    // MARK: Block Button Tap
    @IBAction func blockButtonTap(_ sender: Any) {
        self.blockGenerator.impactOccurred()
        let throttler = Throttler(minimumDelay: 3)
        blocking = !blocking
        switch blocking {
        case true:
            DispatchQueue.main.async {
                self.blockButton.setTitle("Unblock", for: .normal)
            }
            throttler.throttle( {
                self.blockUser()
            },uniqueId: nil)
        case false:
            DispatchQueue.main.async {
                self.blockButton.setTitle("Block", for: .normal)
            }
            throttler.throttle( {
                self.unblockUser()
            }, uniqueId: nil)
        }
    }
    

    // MARK: Cell For Item At
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OtherChannelVideoCell", for: indexPath) as? OtherChannelVideoCell else { return UICollectionViewCell() }
        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            cell.layer.borderColor = UIColor.black.cgColor
        } else {
            cell.layer.borderColor = UIColor.white.cgColor
        }
        let Id: String = videos[indexPath.row].videoid
        var resizedImageProcessors: [ImageProcessing] {
            let imageSize = CGSize(width: cell.thumbnailView.frame.width, height: cell.thumbnailView.frame.height)
            return [ImageProcessors.Resize(size: imageSize, contentMode: .aspectFill)]
        }
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(Id).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let imageUrl = JSON!["thumbnail_url"] as? String else { return }
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
                    Nuke.loadImage(with: request, into: cell.thumbnailView)
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
        let videoid: String
        init(videoid: String) {
            self.videoid = videoid
        }
    }
    
    
    // MARK: Load the channel's videos
    func channelVideoIds() {
        let url = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/channelvideos/\(chanelVar)")
        guard let downloadURL = url else { return }
        let parameters = ["page" : "\(currentPage)"]
        AF.request(downloadURL, method: .get, parameters: parameters).responseJSON { response in
            guard let data = response.data else {
                print("error code: asdfh239419tugisdj")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                self.videos = downloadedVideo.videos
                if self.videos.count < 10 {
                    self.shouldBatchFetch = false
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("error code: asdfasfasdfar23542325, controller: otherchannel, error: \(error)")
                return
            }
        }
    }
    
    
    // MARK: Back Button Function
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Eh
        ImageCache.shared.ttl = 120
        collectionView.refreshControl = refreshControl
        
        // Taps for avatars and follower/ing (they're labels)
        refreshControl.addTarget(self, action: #selector(refreshVideos(_:)), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(OtherChannelViewController.tapppFunction))
        avatarImage.addGestureRecognizer(tappp)
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        
        // Load channel + videos
        loadMemberChannel()
        channelVideoIds()
        
        // dropdown
        let almostwhite = CGColor.init(red: 252, green: 252, blue: 252, alpha: 100)
        self.dropDownStack.frame.size.width = self.avatarImage.bounds.width
        self.dropDownButtons.forEach({ button in
            button.layer.borderColor = almostwhite
            button.layer.borderWidth = 1
            button.isHidden = true
        })
        
        // Seperation line
        let lineView = UIView()
        self.view.addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        lineView.centerYAnchor.constraint(equalTo: self.bioLabel.bottomAnchor, constant: 15).isActive = true
        
        // Setting colors based on dark mode on or off
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            lineView.backgroundColor = UIColor.black
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
            self.collectionView.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
            self.collectionView.backgroundColor = UIColor(hexString: "#141414")
            lineView.backgroundColor = UIColor.white
        }
        
        // Make images look better
        self.avatarImage.contentScaleFactor = 1.5
        let contentModes = ImageLoadingOptions.ContentModes(
          success: .scaleAspectFill,
          failure: .scaleAspectFit,
          placeholder: .scaleAspectFit)
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = UIImage(named: "load-image")
        ImageLoadingOptions.shared.failureImage = UIImage(named: "load-image")
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.2)
        DataLoader.sharedUrlCache.diskCapacity = 0
        
        // Fetch username from segue (faster) and set the nav title
        guard let username = self.segueUsername else { return }
        self.navigationItem.title = "@" + username
        
        // Collection View
        self.collectionView.dataSource = self
        self.collectionView.prefetchDataSource = self
        self.collectionView.isPrefetchingEnabled = true
    }
    
    
    // MARK: Video reload timer
    func videoReloadTimer(invalidate: Bool) {
        Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true, block: { timer in
            if invalidate == true {
                timer.invalidate()
            } else {
                if self.timesReload <= 5 {
                    self.channelVideoIds()
                    self.timesReload = self.timesReload + 1
                } else {
                    timer.invalidate()
                }
            }
        })
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
        self.videoReloadTimer(invalidate: false)
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadSegueInfo()
        loadMemberChannel()
        checkForFollowing()
        checkIfOtherUserIsCurrentUser()
        self.videoReloadTimer(invalidate: true)
    }
    
    
    // MARK: Follower Tap
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    
    
    // MARK: Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Dropdown menu tap
    @objc func tapppFunction(sender:UITapGestureRecognizer) { /// These god damn names, [tap, tapp, tappp, tapppp]. what and why the hell
        self.followGenerator.prepare()
        self.blockGenerator.prepare()
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
            switch blocking {
            case true:
                DispatchQueue.main.async {
                    self.blockButton.setTitle("Unblock", for: .normal)
                }
            case false:
                DispatchQueue.main.async {
                    self.blockButton.setTitle("Block", for: .normal)
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
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let params = [
            "username": "\(chanelVar)"
        ] as [String: String]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/apirelationships/\(relationshipId)")
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
    
    
    // MARK: Unblock the user
    func unblockUser() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let params = [
            "username": chanelVar
        ] as [String: String]
        let url = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/blocks/\(blockId)")
        AF.request(url!, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                switch status {
                case "User has been unblocked":
                    self.blocking = false
                case "User has not been blocked":
                    self.blocking = false
                case .none:
                    print("error code: 10cka043")
                    return
                case .some(_):
                    print("eror code: v0bk4r04323ef")
                    return
                }
            } catch {
                print("error code: 1039574638")
                return
            }
        }
    }
    
    
    // MARK: Block the user
    func blockUser() {
        guard let accessToken: String = try? tokenValet.string(forKey: "Token") else { return }
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/blocks/")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
        let params = [
            "id": chanelVar
        ] as [String: String]
        AF.request(myUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else {
                print("error code: a0vob94mf9a2")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let status: String? = parseJSON["status"] as? String
                    guard let blockId: String = parseJSON["blocked_id"] as? String else { return }
                    switch status {
                    case "User has been blocked":
                        self.blocking = true
                        self.blockId = blockId
                    case "User is already blocked":
                        self.blocking = true
                        self.blockId = blockId
                    case .none:
                        print("error code: 9nka0vmf9s32")
                        return
                    case .some(_):
                        print("error code: 10fka94k2")
                        return
                    }
                }
            } catch {
                
            }
        }
    }
    
    
    // MARK: Follow the user
    func followUser() {
        guard let accessToken: String = try? tokenValet.string(forKey: "Token") else { return }
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/apirelationships/")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let params = ["id": chanelVar] as [String: String]
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
                    guard let relationshipId: String = parseJSON["relationship_id"] as? String else { return }
                    if status == "User Followed" {
                        self.following = true
                        self.relationshipId = relationshipId
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
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/isuserfollowing/\(chanelVar).json")
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
                    guard let relationshipId: String = parseJSON["relationship_id"] as? String else { return }
                    guard let blockId: String = parseJSON["block_id"] as? String else { return }
                    switch status {
                    case "User is not following or blocking":
                        self.following = false
                        self.blocking = false
                    case "User is not following but blocking":
                        self.following = false
                        self.blocking = true
                        self.blockId = blockId
                    case "User is following but not blocking":
                        self.following = true
                        self.blocking = false
                        self.relationshipId = relationshipId
                    case "User is following and blocking":
                        self.following = true
                        self.blocking = true
                        self.relationshipId = relationshipId
                        self.blockId = blockId
                    case .none:
                        print("error code: q01039bjtasme923hf7")
                    case .some(_):
                        print("error code: ajh943l")
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
        guard let token: String  = try? self.tokenValet.string(forKey: "Token") else { return }
        guard let Id: String  = try? self.myValet.string(forKey: "Id") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/registrations/\(Id)")
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
    

    // MARK: Load the user's channel info
    func loadMemberChannel() {
        if avatarUrl != nil, let avatar = avatarUrl, let avatarUrl = URL(string: avatar) {
            DispatchQueue.main.async {
                self.loadImage(url: avatarUrl)
            }
        }
        let Id = chanelVar
        guard let accessToken: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(Id)", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later. :(", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                return
            }
            var parseJSON: [String: Any]?
            do {
                parseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let username: String = parseJSON?["username"] as? String else { return }
                self.channelUsername = username
                DispatchQueue.main.async {
                    self.navigationItem.title = "@" + username
                }
                guard let name: String = parseJSON?["name"] as? String else { return }
                let imageUrl: String? = parseJSON?["avatar_url"] as? String // Forgot to change to the new api here
                guard let followerCount: Int = parseJSON?["followers_count"] as? Int else { return }
                guard let followingCount: Int = parseJSON?["following_count"] as? Int else { return }
                guard let isBlocked: Bool = parseJSON?["isblocked"] as? Bool else { return }
                guard let isReported: Bool = parseJSON?["reported"] as? Bool else { return }
                self.isReported = isReported
                DispatchQueue.main.async {
                    self.reportButton.isHidden = true
                }
                let bio: String = parseJSON?["bio"] as? String ?? "No bio :("
                guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                DispatchQueue.main.async {
                    self.usernameLabel.text = username
                    self.nameLabel.text = name
                    self.bioLabel.text = bio
                }
                switch isBlocked {
                case true:
                    DispatchQueue.main.async {
                        self.collectionView.isHidden = true
                        self.userBlockedLabel.isHidden = false
                    }
                case false:
                    break
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
                        self.followersLabel.text = "\(followerCount)"
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
                    self.loadImage(url: railsUrl)
                    //Nuke.loadImage(with: railsUrl, into: self.avatarImage)
                }
            } catch {
                print("error code: 12ejasdcvcxicvnz9234hrasdf")
                return
            }
        }
    }
    
    
    // MARK: Touch End For Dropdown
    func touchesEnded(touches: NSSet, withEvent event: UIEvent)
    {
        super.touchesEnded(touches as! Set<UITouch>, with: event)
        dismissView()
    }
    
    
    // MARK: Dismiss The Dropdown
    func dismissView() {
        if followButton.isHidden == false && blockButton.isHidden == false && isItThemselves == false {
            dropDownButtons.forEach { (button) in
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = !button.isHidden
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
        self.view.gestureRecognizers?.forEach(view.removeGestureRecognizer)
    }
    
    
    // MARK: Segue Info
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.destination {
        case is OtherFollowerListViewController:
            let vc = segue.destination as? OtherFollowerListViewController
            if segue.identifier == "showOtherFollower" {
                vc?.followerVar = channelUsername
                vc?.userIsSelf = false
            }
        case is OtherFollowListViewController:
            let vc = segue.destination as? OtherFollowListViewController
            if segue.identifier == "showOtherFollowing" {
                vc?.followingVar = channelUsername
                vc?.userIsSelf = false
            }
        case is ChannelVideoViewController:
            let vc = segue.destination as? ChannelVideoViewController
            if segue.identifier == "showOtherVideo" {
                if let indexPath = collectionView?.indexPathsForSelectedItems?.first { /// Come on! There has to be a better way than two consecutive if statements
                    let selectedRow = indexPath.row
                    vc?.videoString = videos[selectedRow].videoid
                    vc?.channelId = chanelVar
                    vc?.rowNumber = indexPath.item
                    vc?.isItFromSearch = false
                }
            } else if segue.identifier == "showOtherVideoo" { /// Are you serious? What is this segue name
                if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                    let selectedRow = indexPath.row
                    vc?.videoString = videos[selectedRow].videoid
                }
            }
        default:
            break
        }
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
    
    func loadImage(url: URL) {
      let resizedImageRequest = ImageRequest(
        url: url,
        processors: resizedImageProcessors)
        let originalImagePublisher = ImagePipeline.shared.imagePublisher(with: url)
        guard let failedImage = ImageLoadingOptions.shared.failureImage else {
            Nuke.loadImage(with: url, into: self.avatarImage)
            return
        }
      
      let resizedImagePublisher = ImagePipeline.shared
        .imagePublisher(with: resizedImageRequest)
        
        cancellable = resizedImagePublisher.append(originalImagePublisher)
            .map {
              ($0.image, UIView.ContentMode.scaleAspectFill)
            }
            .catch { _ in
              Just((failedImage, .scaleAspectFit))
            }
            .sink {
              self.avatarImage.image = $0
              self.avatarImage.contentMode = $1
            }
        if self.avatarImage == nil {
            Nuke.loadImage(with: url, into: self.avatarImage)
        }
    }

    
}
