//
//  FirstViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//
// EAT THE HAMCAT

import UIKit
import Valet
import UserNotifications
import AsyncDisplayKit
import Nuke
import Alamofire
import TTGSnackbar

class HomeViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate, ChannelVideoOverlayViewDelegate {
    
    
    
    // MARK: Present Alert
    // This is for alerts from the overlay view
    func willPresentAlert(alertController: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: Report from delegate
    func didPressReport(videoId: String) {
        popupMessages().showMessageWithOptions(title: "Hey!", message: "Are you sure that you would like to report this video?", firstOptionTitle: "Yes", secondOptionTitle: "Nahhhh", viewController: self, {
            guard let token: String = try? self.tokenValet.string(forKey: "Token") else { return }
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ]
            let params = [
                "video_id": videoId
            ]
            AF.request("https://www.blurrmc.com/api/v1/reports", method: .post, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                guard let response = response.data else {
                    let snackbar = TTGSnackbar(message: "Error reporting the video. Maybe try later.", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                    return
                }
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any]
                    let status = JSON!["status"] as? String
                    if status != "Reported" {
                        let snackbar = TTGSnackbar(message: "Error reporting the video. Maybe try later.", duration: .middle)
                        DispatchQueue.main.async {
                            snackbar.show()
                        }
                        print("error code: afidj98j34fw9euainsdf")
                    }
                } catch {
                    print(error)
                    print("error code: adsv4837uehrafidsun")
                    let snackbar = TTGSnackbar(message: "Error reporting the video. Maybe try later.", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                    return
                }
            }
        })
    }
    
    
    func switchedPreference(newPreference: WatchingPreference) {
        self.watchingPreference = newPreference
        self.homeFeedRequest()
    }
    
    // Variables
    var watchingPreference: WatchingPreference = .following
    var shouldBatchFetch = true
    var oldVideoCount = 0
    var resizedImageProcessors = [ImageProcessing]()

    @IBOutlet weak var progressView: UIProgressView!
    
    
    
    // MARK: From delegate, for sharing
    func didTapShare(_ view: ChannelVideoOverlayView, videoUrl: String, videoId: String) {
        shareWindow(videoUrl: videoUrl, videoId: videoId)
    }
    
    
    // MARK: Tap for channel from overlay
    func didTapChannel(_ view: ChannelVideoOverlayView, videousername: String, resizedImageProcessor: [ImageProcessing], isReported: Bool, isBlocked: Bool, name: String) {
        self.resizedImageProcessors = resizedImageProcessor
        self.reported = isReported
        self.blocked = isBlocked
        self.name = name
        showUserChannel(videoUsername: videousername)
    }
    
    
    // MARK: Tap for comments from overlay
    func didTapComments(_ view: ChannelVideoOverlayView, videoid: String) {
        showVideoComments(videoId: videoid)
    }
    
    
    // MARK: Setup window for sharing functionality
    // This may use A LOT of ram over a long period of time. Possible fix: deleting cache after user is done dealing with video?
    func shareWindow(videoUrl: String, videoId: String) {
        CacheManager.shared.getFileWith(stringUrl: videoUrl) { result in
                switch result {
                case .success(let url):
                    let videoToShare = [ url ]
                    let activityViewController = UIActivityViewController(activityItems: videoToShare as [Any], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.postToFlickr,
                        UIActivity.ActivityType.postToTwitter, UIActivity.ActivityType.postToTencentWeibo
                    ]
                    DispatchQueue.main.async {
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    activityViewController.completionWithItemsHandler = { activity, completed, items, error in
                            if !completed {
                                guard let url = URL(string: videoUrl) else { return }
                                CacheManager.shared.clearContents(url) // Clearing the cache still doesn't work!?
                                return
                            }
                        }
                case .failure( _):
                    // Share the url of the video if downloading the video did not work (backup method)
                    let videoToShare = [ URL(string: "https://www.blurrmc.com/videos/\(videoId)") ]
                    let activityViewController = UIActivityViewController(activityItems: videoToShare as [Any], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.postToFlickr,
                        UIActivity.ActivityType.postToTwitter, UIActivity.ActivityType.postToTencentWeibo
                    ]
                    DispatchQueue.main.async {
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    activityViewController.completionWithItemsHandler = { activity, completed, items, error in
                            if !completed {
                                return
                            }
                        }
                }
        }
    }
    
    @available(*, deprecated, renamed: "homeFeedRequest")
    func getRandomVideos() { }
    
    // MARK: Get Videos For Home Page
    func homeFeedRequest() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        var url = URL(string: "https://www.blurrmc.com/api/v1/apihomefeed")
        switch self.watchingPreference {
        case .following:
            url = URL(string: "https://www.blurrmc.com/api/v1/apihomefeed")
        case .trending:
            url = URL(string: "https://www.blurrmc.com/api/v1/trending")
        }
        
        AF.request(url!, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: 1kdm03o4-2")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                self.videos = downloadedVideo.videos
                DispatchQueue.main.async {
                    self.tableNode.reloadData()
                }
            } catch {
                print("error code: 1kasfio23uena, controller: homeview, error: \(error)")
                return
            }
        }
    }
    
    
    // MARK: Batch Fetch Request
    func batchFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://www.blurrmc.com/api/v1/apihomefeed", method: .post, parameters: parameters, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                success(response)
            case .failure(let error):
                failure(error as NSError)
            }
            
        }
    }
    

    // MARK: Function for showing user channel
    func showUserChannel(videoUsername: String) {
        self.videoUsername = videoUsername
        self.performSegue(withIdentifier: "showHomeVideoUserChannel", sender: self)
    }
    
    // MARK: Function for showing video comments
    func showVideoComments(videoId: String) {
        self.videoId = videoId
        let storyboard = UIStoryboard(name: "CommentBoard", bundle: nil)
        let commentNavController = storyboard.instantiateViewController(withIdentifier: "commentNav") as! UINavigationController
        let commentController = commentNavController.viewControllers.first as! CommentingViewController
        commentController.videoId = self.videoId
        commentNavController.modalPresentationStyle = .formSheet
        DispatchQueue.main.async {
            self.present(commentNavController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Table node frame
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableNode.frame = self.view.bounds
        
    }
    
    
    // MARK: Segue Data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let vc = segue.destination as? OtherChannelViewController {
            if segue.identifier == "showHomeVideoUserChannel" {
                vc.chanelVar = videoUsername
                vc.resizedImageProcessors = self.resizedImageProcessors
                vc.channelUsername = videoUsername
                vc.segueUsername = videoUsername
                vc.segueName = name
                vc.isReported = reported
            }
        }
    }
    
    // MARK: Variables
    var window: UIWindow?
    var videoId = String()
    var videoUsername = String()
    var tableNode: ASTableNode!
    var lastNode: ChannelVideoCellNode?
    private var videos = [Video]()
    var currentPage: Int = 1
    var name = String()
    var reported = Bool()
    var blocked = Bool()
    
    
    // MARK: Videos downloaded
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    
    class Video: Codable {
        let videourl: String
        let videoid: String
        init(videourl: String, videoid: String) {
            self.videourl = videourl
            self.videoid = videoid
        }
    }

    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Delegates
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // MARK: Styling for table node
    func applyStyle() {
        let tableView = self.tableNode.view
        //let margins = view.layoutMarginsGuide
        tableView.separatorStyle = .none
        tableView.isPagingEnabled = true
        /*tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0).isActive = true
        tableView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 0).isActive = true*/
    }
    
    // MARK: Delegates for table node
    func wireDelegates() {
        self.tableNode.delegate = self
        self.tableNode.dataSource = self
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Home"
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        self.tableNode = ASTableNode(style: .plain)
        self.wireDelegates()
        self.view.insertSubview(tableNode.view, at: 0)
        self.applyStyle()
        self.tableNode.leadingScreensForBatching = 1.0
        homeFeedRequest()
        checkUser() // This doesn't have to be the first thing
        // Upload video notification complete
        NotificationCenter.default.addObserver(self, selector: #selector(videoUploadedNotification(_:)), name: .didUploadVideo, object: nil)
    }
    
    // MARK: Received notifcation that video has been uplaoded
    @objc func videoUploadedNotification(_ notification: Notification) {
        if let data = notification.userInfo as? [String: Any] {
            let errorSnackBar = TTGSnackbar(
                message: "Video failed to upload!",
                duration: .long
            )
            guard let status: String = data["status"] as? String else {
                DispatchQueue.main.async {
                    errorSnackBar.show()
                }
                return
            }
            if status == "Video Uploaded" {
                guard let id: String = data["video_id"] as? String else { return }
                let successSnackBar = TTGSnackbar(
                    message: "Video uploaded!",
                    duration: .middle,
                    actionText: "Undo",
                    actionBlock: { snackbar in
                        guard let token: String = try? self.tokenValet.string(forKey: "Token") else { return }
                        let headers: HTTPHeaders = [
                            "Authorization": "Bearer \(token)",
                            "Accept": "application/json"
                        ]
                        let params = [
                            "video": id
                        ]
                        AF.request("https://www.blurrmc.com/api/v1/registernotificationtoken", method: .post, parameters: params,headers: headers).responseJSON { response in
                            guard let data = response.data else {
                                print("error code: eajf9sdiofjkz, also btw if anybody else other martin is reading this then, just saying, these error codes mean nothing. Do not try to decode them martin just smashed his head against the keyboard for each error code")
                                return
                            }
                            do {
                                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                                if let parseJSON = json {
                                    guard let status: String = parseJSON["status"] as? String else { return }
                                    if status == "Da video is gone just like the infinity stones!!!" {
                                        let happySnackBar = TTGSnackbar(
                                            message: "The video has been destroyed :)",
                                            duration: .long
                                        )
                                        DispatchQueue.main.async {
                                            happySnackBar.show()
                                        }
                                    } else {
                                        let sadSnackBar = TTGSnackbar(
                                            message: "The video could not be destroyed :(",
                                            duration: .long
                                        )
                                        DispatchQueue.main.async {
                                            sadSnackBar.show()
                                        }
                                    }
                                }
                            } catch {
                                print("error code: asdfj83qwaefouisdzn, error: \(error)")
                                return
                            }
                        }
                    }
                )
                DispatchQueue.main.async {
                    successSnackBar.show()
                }
            } else {
                DispatchQueue.main.async {
                    errorSnackBar.show()
                }
            }
        }
    }
    
    
    // MARK: Check user's account to make sure it's valid
    func checkUser() {
        guard let accessToken: String = try? tokenValet.string(forKey: "Token") else { return }
        guard let userId: String = try? myValet.string(forKey: "Id") else { return }
        guard let myUrl = URL(string: "https://www.blurrmc.com/api/v1/isuservalid/\(userId)") else { return }
        var request = URLRequest(url:myUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print("there is an error")
                return
            }
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let status: String? = parseJSON["status"] as? String
                    switch status {
                    case "User is valid! YAY :)":
                        self.sendNotificationTokenToServer()
                    case "User is not valid. Oh no!":
                        try self.myValet.removeObject(forKey: "Id")
                        try self.tokenValet.removeObject(forKey: "Token")
                        try self.tokenValet.removeObject(forKey: "NotificationToken")
                        try self.myValet.removeAllObjects()
                        try self.tokenValet.removeAllObjects()
                        let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                        self.present(loginPage, animated:false, completion:nil)
                        self.window =  UIWindow(frame: UIScreen.main.bounds)
                        self.window?.rootViewController = loginPage
                        self.window?.makeKeyAndVisible()
                    case .none:
                        break
                    case .some(_):
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 404 {
                                try self.myValet.removeObject(forKey: "Id")
                                try self.tokenValet.removeObject(forKey: "Token")
                                try self.myValet.removeAllObjects()
                                try self.tokenValet.removeAllObjects()
                                DispatchQueue.main.async {
                                    let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    self.present(loginPage, animated: true, completion: nil)
                                    self.window?.rootViewController = loginPage
                                }
                            }
                        } else {
                            break
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
    
    // MARK: Send the notification token to the server
    func sendNotificationTokenToServer() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        guard let notificationToken: String = try? tokenValet.string(forKey: "NotificationToken") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let parameters: Parameters = [
            "token": notificationToken
        ]
        AF.request("https://www.blurrmc.com/api/v1/registernotificationtoken", method: .post, parameters: parameters,headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: 98ijorkndfms,cx")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    guard let status: String = parseJSON["status"] as? String else { return }
                    if status != "Token has been saved" {
                        print("notification token could not save, error code: 10ejasnfasdfk9, status: \(status)")
                    }
                }
            } catch {
                print("error code: f1e1212313123123, error: \(error)")
                return
            }
        }
    }
    
    
    // MARK: New rows for table node
    func insertNewRowsInTableNode(newVideos: [Video]) {
        guard newVideos.count > 0 else {
            return
        }
        let section = 0
        var indexPaths: [IndexPath] = []
        let total = self.videos.count + newVideos.count
        for row in self.videos.count...total-1 {
            let path = IndexPath(row: row, section: section)
            indexPaths.append(path)
        }
        self.videos.append(contentsOf: newVideos)
        if (oldVideoCount + newVideos.count) == self.videos.count {
            self.tableNode.insertRows(at: indexPaths, with: .none)
        } else {
            return
        }
    }

}
extension HomeViewController: ASTableDataSource {
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let videourll = self.videos[indexPath.row].videourl
        let videoId = self.videos[indexPath.row].videoid
        let videoUrl = URL(string: videourll)
        var firstVideo: Bool = false
        if indexPath.row == 1 {
            firstVideo = true
        }
        return {
            let node = ChannelVideoCellNode(with: videoUrl!, videoId: videoId, doesParentHaveTabBar: true, firstVideo: firstVideo)
            node.delegate = self
            node.debugName = "\(self.videos[indexPath.row].videoid)"
            return node
        }
    }
}
extension HomeViewController: ASTableDelegate {
    
    // MARK: Size of each cell
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let width = UIScreen.main.bounds.size.width
        let min = CGSize(width: width, height: (UIScreen.main.bounds.size.height/3) * 2)
        let max = CGSize(width: width, height: .infinity)
        return ASSizeRangeMake(min, max)
    }
    
    // MARK: Batch fetch bool
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        return shouldBatchFetch
    }
    
    // MARK: Batch fetch
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        oldVideoCount = self.videos.count
        currentPage = currentPage + 1
        self.batchFetch(success: {(response) -> Void in
            guard let data = response?.data else {
                print("error code: 1kdm03o4-2")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                if downloadedVideo.videos.count < 5 {
                    self.shouldBatchFetch = false
                }
                self.insertNewRowsInTableNode(newVideos: downloadedVideo.videos)
                context.completeBatchFetching(true)
            } catch {
                print("error code: g09an242, controller: homeview, error: \(error)")
                return
            }
        }, failure: { (error) -> Void in
            print("error code: 1kd03l103-2")
            print(error as Any)
        })
    }
}
extension Notification.Name {
    static let didUploadVideo = Notification.Name("uploadedVideo")
}

