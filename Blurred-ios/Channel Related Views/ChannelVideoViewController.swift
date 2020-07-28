//
//  ChannelVideoViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Valet
import Alamofire
import Nuke
import Photos

class ChannelVideoViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var backButtonOutlet: UIButton!
    @IBOutlet weak var share: UIImageView!
    var videoUsername = String()
    var nextVideoId = Int()
    var previousvideoId = Int()
    var lastVideo = Bool()
    var firstVideo = Bool()
    @IBOutlet weak var videoUserAvatar: UIImageView!
    @IBOutlet weak var videoLike: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var videoString = Int()
    var videoUrlString = String()
    var likeId = Int()
    var isVideoLiked = Bool()
    var likenumber = Int()
    var videoDescription = String()
    var publishdate = String()
    var views = Int()
    var isItSwitched: Bool = false
    override func didReceiveMemoryWarning() {
        avPlayerLayer = nil
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    // MARK: Setup window for sharing functionality
    func shareWindow() {
        avPlayer.pause()
        CacheManager.shared.getFileWith(stringUrl: "http://10.0.0.2:3000\(videoUrlString)") { result in
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
                                self.avPlayer.play()
                                CacheManager.shared.clearContents(url) // Clearing the cache still doesn't work!
                                return
                            }
                        self.avPlayer.play()
                        }
                case .failure( _): break
                }
        }
        
    }
    // MARK: Check the like count of video and set it
    func checkLikeCount() {
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(videoString).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let likecount = JSON!["likecount"] as? Int else { return }
                    if likecount != 0 {
                        if likecount > 1000 {
                                DispatchQueue.main.async {
                                    self.likeCount.text = "\(likecount/1000).\((likecount/100)%10)k"
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.likeCount.text = "\(likecount )"
                                }
                                self.likenumber = likecount
                        }
                        if likecount >= 100000 {
                                DispatchQueue.main.async {
                                    self.likeCount.text = "\(likecount/1000)k"
                                }
                            }
                        if likecount >= 1000000 {
                                DispatchQueue.main.async {
                                    self.likeCount.text = "\(likecount/1000000).\((likecount/1000)%10)M"
                                }
                            }
                        if likecount >= 10000000 {
                                // Add more if someone's account goes over 999M followers.
                                DispatchQueue.main.async {
                                    self.likeCount.text = "\(likecount/1000000)M"
                                }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.likeCount.text = "0"
                        }
                    }
            } catch {
                self.showErrorContactingServer()
            }
        }
    }
    // MARK: Checks if user liked video
    func sendCheckLikeRequest() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoString)/didyoulikeit/")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status == "This video is liked." {
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart.fill")
                        self.videoLike.tintColor = UIColor.systemRed
                    }
                    guard let likeid = JSON!["likeid"] as? Dictionary<String, Any> else { return }
                    guard let id = likeid["id"] as? Int else { return }
                    self.likeId = id
                    self.isVideoLiked = true
                } else if status == "Video has not been liked" {
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart")
                        self.videoLike.tintColor = UIColor.lightGray
                    }
                    self.isVideoLiked = false
                } else {
                    print("error code: 1039574612")
                    return
                }
            } catch {
                print("error code: 1039574638")
                return
            }
            }
    }
    // MARK: Delete's the like
    func sendDeleteLikeRequest() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoString)/apilikes/\(likeId)")
        AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Video has been unliked." && status == "You have not liked this!" {
                    self.sendLikeRequest()
                } else if status == "Video has been unliked." {
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart")
                        self.videoLike.tintColor = UIColor.lightGray
                    }
                }
                self.checkLikeCount()
                self.sendCheckLikeRequest()
            } catch {
                print("error code: 1972026583")
                return
            }
            }
    }
    // MARK: Sends request to like the video
    func sendLikeRequest() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoString)/apilikes/")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Video has been liked" && status == "You have already liked it!" {
                    self.sendDeleteLikeRequest()
                } else if status == "Video has been unliked." {
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart")
                        self.videoLike.tintColor = UIColor.lightGray
                    }
                } else if status == "Video has been liked" {
                    DispatchQueue.main.async {
                        DispatchQueue.main.async {
                            self.videoLike.image = UIImage(systemName: "heart.fill")
                            self.videoLike.tintColor = UIColor.systemRed
                        }
                    }
                }
                self.checkLikeCount()
                self.sendCheckLikeRequest()
            } catch {
                print("error code: 1972026583")
                return
            }
            }
    }
    // MARK: Send request for video info
    func sendRequest() {
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(videoString).json")
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
                    let publishDate: String? = parseJSON["publishdate"] as? String
                    guard let viewCount: Int = parseJSON["viewcount"] as? Int else { return }
                    guard let videoUrl: String = parseJSON["video_url"] as? String else { return }
                    let descriptionString: String? = parseJSON["description"] as? String
                    guard let username: String = parseJSON["username"] as? String else { return }
                    let nextVideo = parseJSON["nextvideoid"] as? Int
                    let previousVideo = parseJSON["previousvideoid"] as? Int
                    self.previousvideoId = previousVideo ?? 0
                    self.nextVideoId = nextVideo ?? 0
                    self.videoUsername = username
                    self.views = viewCount
                    self.publishdate = publishDate ?? "February 3rd 2007"
                    self.videoDescription = descriptionString ?? ""
                    AF.request("http://10.0.0.2:3000/api/v1/channels/\(String(describing: username)).json").responseJSON {   response in
                               var JSON: [String: Any]?
                               do {
                                   JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                                   let avatarUrl = JSON!["avatar_url"] as? String
                                   let railsUrl = URL(string: "http://10.0.0.2:3000\(avatarUrl!)")
                                guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {
                                    return
                                }
                                   DispatchQueue.main.async {
                                    Nuke.loadImage(with: railsUrl ?? imageURL, into: self.videoUserAvatar)
                                   }
                               } catch {
                                   return
                               }
                    }
                    self.videoUrlString = videoUrl
                    DispatchQueue.main.async {
                        self.descriptionLabel.text = descriptionString
                        self.babaPlayer()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer()
                    }
                    print(error ?? "")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
                print(error)
                }
        }
        task.resume()
    }
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        isDismissed = true
        avPlayer.pause()
    }
    func play() {
        avPlayer.play()
        isDismissed = false
    }
    func presentationControllerWillDismiss(_: UIPresentationController) {
        isDismissed = false
        avPlayer.play()
    }
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var commentImage: UIImageView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = CommentingViewController()
        vc.presentationController?.delegate = self
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        sendRequest()
        self.videoView.isUserInteractionEnabled = true
        // MARK: Tap recognizers
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tapppFunction))
        let liketap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.liketapFunction))
        let sharetap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.sharetapFunction))
        let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.descriptiontapFunction))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(videoSwipe))
        swipeDown.direction = .down
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(videoSwipe))
        swipeUp.direction = .up
        videoView.addGestureRecognizer(swipeUp)
        videoView.addGestureRecognizer(swipeDown)
        descriptionLabel.addGestureRecognizer(descriptiontap)
        share.addGestureRecognizer(sharetap)
        commentImage.addGestureRecognizer(tappp)
        videoUserAvatar.addGestureRecognizer(tapp)
        videoLike.addGestureRecognizer(liketap)
        videoView.addGestureRecognizer(tap)
        backButtonOutlet.layer.zPosition = 1
        videoUserAvatar.layer.zPosition = 2
    }
    @objc func videoSwipe(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            case .down:
                // Go to previous video
                print("swiped down")
            case .up:
                // Go to next video.
                print("swiped up")
            default:
                break
            }
        }
    }
    var doubleTap : Bool! = false
    // MARK: Pauses/Plays the video
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        if (doubleTap) {
            doubleTap = false
            avPlayer.play()
        } else {
            avPlayer.pause()
            doubleTap = true
        }
    }
    // MARK: Video views + publish date
    @objc func descriptiontapFunction(sender:UITapGestureRecognizer) {
        if isItSwitched == false {
            var viewCount = String()
            switch views {
            case _ where views > 1000 && views < 100000:
                DispatchQueue.main.async {
                    viewCount = "\(self.views/1000).\((self.views/100)%10)k Views"
                }
            case _ where views > 100000 && views < 1000000:
                DispatchQueue.main.async {
                    viewCount = "\(self.views/1000)k Views "
                }
            case _ where views > 1000000 && views < 100000000:
                DispatchQueue.main.async {
                    viewCount = "\(self.views/1000000).\((self.views/1000)%10)M Views"
                }
            case _ where views > 100000000:
                DispatchQueue.main.async {
                    viewCount = "\(self.views/1000000)M Views"
                }
            case _ where views == 1:
                DispatchQueue.main.async {
                    viewCount = "\(self.views) View"
                }
            default:
                DispatchQueue.main.async {
                    viewCount = "\(self.views) Views"
                }
            }
            DispatchQueue.main.async {
                let newDescription: String = "\(self.publishdate) \n\(viewCount)"
                self.descriptionLabel.text = newDescription
            }
            isItSwitched = true
        } else if isItSwitched == true {
            DispatchQueue.main.async {
                self.descriptionLabel.text = self.videoDescription
            }
            isItSwitched = false
        }
    }
    @objc func sharetapFunction(sender:UITapGestureRecognizer) {
        shareWindow()
    }
    // MARK: Like button tapped
    @objc func liketapFunction(sender:UITapGestureRecognizer) {
        if isVideoLiked == true {
            DispatchQueue.main.async {
                self.videoLike.image = UIImage(systemName: "heart")
                self.videoLike.tintColor = UIColor.lightGray
            }
            if likenumber != 0 {
                let subtot = likenumber - 1
                
                let subby = String("\(subtot)")
                DispatchQueue.main.async {
                    self.likeCount.text = subby
                }
            }
            sendDeleteLikeRequest()
            isVideoLiked = false
        } else if isVideoLiked == false {
            DispatchQueue.main.async {
                self.videoLike.image = UIImage(systemName: "heart.fill")
                self.videoLike.tintColor = UIColor.systemRed
            }
            if likenumber != 0 {
                likenumber = likenumber - 1 
                let subtot = likenumber + 1
                let subby = String("\(subtot)")
                DispatchQueue.main.async {
                    self.likeCount.text = subby
                }
            }
            sendLikeRequest()
            isVideoLiked = true
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is OtherChannelViewController
        {
            if let vc = segue.destination as? OtherChannelViewController {
                if segue.identifier == "showVideoUserChannel" {
                    vc.chanelVar = videoUsername
                }
            }
        } else if let vc = segue.destination as? CommentingViewController {
            if segue.identifier == "showComments" {
                vc.presentationController?.delegate = self
                vc.videoId = videoString
            }
        }
    }
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "showVideoUserChannel", sender: self)
    }
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        avPlayer.pause()
        isDismissed = true
        self.performSegue(withIdentifier: "showComments", sender: self)
        //let vc = CommentingViewController()
        //self.present(vc, animated: true, completion: nil)
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    var isDismissed: Bool = false
    fileprivate var playerObserver: Any?
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        isDismissed = true
        avPlayerLayer = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        sendRequest()
        sendCheckLikeRequest()
        checkLikeCount()
        isDismissed = false
    }
    fileprivate var player: AVPlayer? {
        didSet { player?.play() }
    }
    deinit {
        guard let observer = playerObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    // MARK: Plays the video
    func babaPlayer() {
        let videoUrl = URL(string: "http://10.0.0.2:3000\(videoUrlString)")!
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoUrl as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
        if isDismissed != true {
            let resetPlayer = {
                self.avPlayer.seek(to: CMTime.zero)
                self.avPlayer.play()
            }
            playerObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem, queue: nil) { notification in
                resetPlayer()
            }
        } else {
            avPlayer.pause()
        }
        avPlayer.play()
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
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
}
public enum Result<T> {
    case success(T)
    case failure(NSError)
}
// MARK: Cache manager (For the sharing window)
class CacheManager {

    static let shared = CacheManager()

    private let fileManager = FileManager.default

    private lazy var mainDirectoryUrl: URL = {

        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()
    // MARK: Try and clear the contents of the cache.
    func clearContents(_ url:URL) {

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            let urls = contents.map { URL(string:"\(url.appendingPathComponent("\($0)"))")! }
            urls.forEach {  try? FileManager.default.removeItem(at: $0) }
        }
        catch {

            print(error)

        }

     }
    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL>) -> Void ) {


        let file = directoryFor(stringUrl: stringUrl)

        //return file path if already exists in cache directory
        guard !fileManager.fileExists(atPath: file.path)  else {
            completionHandler(Result.success(file))
            return
        }

        DispatchQueue.global().async {

            if let videoData = NSData(contentsOf: URL(string: stringUrl)!) {
                videoData.write(to: file, atomically: true)

                DispatchQueue.main.async {
                    completionHandler(Result.success(file))
                }
            } else {
                print("error code: 1957329172")
            }
        }
    }

    private func directoryFor(stringUrl: String) -> URL {

        let fileURL = URL(string: stringUrl)!.lastPathComponent

        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)

        return file
    }
}
