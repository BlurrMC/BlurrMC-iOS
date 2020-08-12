//
//  ChannelVideoViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AVFoundation
import Valet
import Alamofire
import Nuke
import Photos
import AsyncDisplayKit

class ChannelVideoViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate {
    var tableNode: ASTableNode!
    var lastNode: ChannelVideoCellNode?
    var amIDone = Bool()
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.tableNode = ASTableNode(style: .plain)
            self.wireDelegates()
    }
    // MARK: Tap function for share window
    @objc func sharetapFunction(sender:UITapGestureRecognizer) {
        // See note below
    }
    
    // MARK: Setup window for sharing functionality (disabled temporarily)
    /*func shareWindow() {
        CacheManager.shared.getFileWith(stringUrl: "\(videoUrl)") { result in
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
                                CacheManager.shared.clearContents(url) // Clearing the cache still doesn't work!
                                return
                            }
                        }
                case .failure( _): break
                }
        }
        
    }*/
    
    private var videos = [Video]()
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var backButtonOutlet: UIButton!
    @IBOutlet weak var share: UIImageView!
    var videoUsername = String()
    var rowNumber = Int()
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
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        isDismissed = true
    }
    func play() {
        avPlayer.play()
        isDismissed = false
    }
    func presentationControllerWillDismiss(_: UIPresentationController) {
        isDismissed = false
        avPlayer.play()
    }
    override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            self.tableNode.frame = self.view.bounds;
    }
    func applyStyle() {
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.isPagingEnabled = true
    }
    func wireDelegates() {
            self.tableNode.delegate = self
            self.tableNode.dataSource = self
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
        // sendRequest(videoid: videoString)
        self.view.insertSubview(tableNode.view, at: 0)
        self.applyStyle()
        self.tableNode.leadingScreensForBatching = 1.0
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
    
    
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    class Video: Codable {
        let videourl: String
        let videoid: Int
        init(videourl: String, videoid: Int) {
            self.videourl = videourl
            self.videoid = videoid
        }
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
        channelVideoIds()
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
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect // Was aspect fill
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
    
    // MARK: Function for user channel
    func showUserChannel() {
        self.performSegue(withIdentifier: "showVideoUserChannel", sender: self)
    }
    
    // MARK: Function for video comments
    func showVideoComments() {
        self.performSegue(withIdentifier: "showComments", sender: self)
    }
    
    var channelId = Int()
    func channelVideoIds() { // Still not done we need to add the user's butt image
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelvideos/\(channelId).json")
        print("\(channelId)")
            guard let downloadURL = url else { return }
            URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
                guard let data = data, error == nil, urlResponse != nil else {
                    print("error code: 1kdm03o4-2")
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    self.videos = downloadedVideo.videos
                    let pathTotRow = IndexPath.init(row: self.rowNumber, section: 0)
                    DispatchQueue.main.async {
                        self.tableNode.reloadData()
                        self.tableNode.scrollToRow(at: pathTotRow, at: .none, animated: false)
                    }
                } catch {
                    print("error code: 1kzka0aww3-2")
                    return
                }
            }.resume()
    }
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
        self.tableNode.insertRows(at: indexPaths, with: .none)
    }
    var shouldWeContinue = Bool()
}
public enum Result<T> {
    case success(T)
    case failure(NSError)
}

extension ChannelVideoViewController: ASTableDataSource {
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        
        let videourll = self.videos[indexPath.row].videourl
        let videoId = self.videos[indexPath.row].videoid
        let videoUrl = URL(string: "http://10.0.0.2:3000\(videourll)")
        return {
            let node = ChannelVideoCellNode(with: videoUrl!, videoId: videoId)
            node.debugName = "\(self.videos[indexPath.row].videoid)"
            return node
        }
    }
}
extension ChannelVideoViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let width = UIScreen.main.bounds.size.width
        let min = CGSize(width: width, height: (UIScreen.main.bounds.size.height/3) * 2)
        let max = CGSize(width: width, height: .infinity)
        return ASSizeRangeMake(min, max)
    }
    
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        return true
    }
    
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        /*channelVideoIds()
        DispatchQueue.main.async {
            self.insertNewRowsInTableNode(newVideos: self.videos)
        }
        context.completeBatchFetching(true)*/
        self.retrieveNextPageWithCompletion { (newVideos) in
            self.insertNewRowsInTableNode(newVideos: newVideos)
            context.completeBatchFetching(true)
        }
    }
}
extension ChannelVideoViewController {
    func retrieveNextPageWithCompletion( block: @escaping ([Video]) -> Void) {
        var oldVideoCount = Int()
        oldVideoCount = videos.count
        channelVideoIds()
        if videos.count > oldVideoCount {
            DispatchQueue.main.async {
                block(self.videos)
            }
        }
    }
}
