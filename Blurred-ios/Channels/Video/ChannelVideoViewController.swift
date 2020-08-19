//
//  ChannelVideoViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Alamofire
import Photos
import AsyncDisplayKit

class ChannelVideoViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate, ChannelVideoOverlayViewDelegate {
    
    
    // MARK: Tap for channel from overlay
    func didTapChannel(_ view: ChannelVideoOverlayView, videousername: String) {
        showUserChannel(videoUsername: videousername)
    }
    
    // MARK: Tap for comments from overlay
    func didTapComments(_ view: ChannelVideoOverlayView, videoid: Int) {
        showVideoComments(videoId: videoid)
    }
    
    // MARK: Variables
    var tableNode: ASTableNode!
    var lastNode: ChannelVideoCellNode?
    private var videos = [Video]()
    var videoUsername = String()
    var rowNumber = Int()
    var videoString = Int()
    var videoUrlString = String()
    var isItFromSearch = Bool()
    var videoId = Int()
    var channelId = String()
    
    
    // MARK: Tap function for share window
    @objc func sharetapFunction(sender:UITapGestureRecognizer) {
        // See note for shareWindow()
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
    
    // MARK: Remove URL Cache
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    // MARK: Back Button Press
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Table node frame
    override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            self.tableNode.frame = self.view.bounds;
    }
    
    // MARK: Styling for table node
    func applyStyle() {
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.isPagingEnabled = true
    }
    
    // MARK: Delegates for table node
    func wireDelegates() {
        self.tableNode.delegate = self
        self.tableNode.dataSource = self
    }
    
    // MARK: Request for channel's videos
    func sendRequest() {
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(videoString).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    guard let videoUrl: String = parseJSON["video_url"] as? String else { return }
                    self.videoUrlString = videoUrl
                    let array: [String : [[String : Any]]] = ["videos": [["videourl": "\(videoUrl)", "videoid": self.videoString]]]
                    let jsonData = try JSONSerialization.data(withJSONObject: array, options: .init(rawValue: 0)) as Data
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: jsonData)
                    self.videos = downloadedVideo.videos
                    DispatchQueue.main.async {
                        self.tableNode.reloadData()
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

    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad() 
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        self.tableNode = ASTableNode(style: .plain)
        self.wireDelegates()
        self.view.insertSubview(tableNode.view, at: 0)
        self.applyStyle()
        self.tableNode.leadingScreensForBatching = 1.0
    }
   
    // MARK: Segue Data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let vc = segue.destination as? CommentingViewController {
            if segue.identifier == "showComments" {
                vc.presentationController?.delegate = self
                vc.videoId = videoId
            }
        } else if let vc = segue.destination as? OtherChannelViewController {
            if segue.identifier == "showVideoUserChannel" {
                vc.chanelVar = videoUsername
            }
        }
    }
    
    // MARK: Videos downloaded
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if isItFromSearch != true {
            channelVideoIds()
        } else {
            sendRequest()
        }
    }
    
    // MARK: Function for showing user channel
    func showUserChannel(videoUsername: String) { 
        self.videoUsername = videoUsername
        self.performSegue(withIdentifier: "showVideoUserChannel", sender: self)
    }
    
    // MARK: Function for showing video comments
    func showVideoComments(videoId: Int) {
        self.videoId = videoId
        self.performSegue(withIdentifier: "showComments", sender: self)
        
    }
    
    // MARK: Download array of videos for channels
    func channelVideoIds() { // Still not done we need to add the user's butt image
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelvideos/\(channelId).json")
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
                print("\(self.channelId)")
                return
            }
        }.resume()
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
        self.tableNode.insertRows(at: indexPaths, with: .none)
    }
    
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
        if isItFromSearch != true {
            let videourll = self.videos[indexPath.row].videourl
            let videoId = self.videos[indexPath.row].videoid
            let videoUrl = URL(string: "http://10.0.0.2:3000\(videourll)")
            return {
                let node = ChannelVideoCellNode(with: videoUrl!, videoId: videoId, doesParentHaveTabBar: false)
                node.delegate = self
                node.debugName = "\(self.videos[indexPath.row].videoid)"
                return node
            }
        } else {
            let url = URL(string: "http://10.0.0.2:3000\(videoUrlString)")!
            return {
                let node = ChannelVideoCellNode(with: url, videoId: self.videoString, doesParentHaveTabBar: false)
                node.delegate = self
                node.debugName = "\(self.videoString)"
                return node
            }
            
        }
    }
}
extension ChannelVideoViewController: ASTableDelegate {
    // MARK: Size of each cell
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let width = UIScreen.main.bounds.size.width
        let min = CGSize(width: width, height: (UIScreen.main.bounds.size.height/3) * 2)
        let max = CGSize(width: width, height: .infinity)
        return ASSizeRangeMake(min, max)
    }
    
    // MARK: Batch fetch bool
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        return true
    }
    
    // MARK: Batch fetch function
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        self.retrieveNextPageWithCompletion { (newVideos) in
            self.insertNewRowsInTableNode(newVideos: newVideos)
            context.completeBatchFetching(true)
        }
        
    }
    
}
extension ChannelVideoViewController {
    // MARK: More batch fetching function
    func retrieveNextPageWithCompletion( block: @escaping ([Video]) -> Void) {
        switch isItFromSearch {
        case false:
            var oldVideoCount = Int()
            oldVideoCount = videos.count
            channelVideoIds()
            if videos.count > oldVideoCount {
                DispatchQueue.main.async {
                    block(self.videos)
                }
            }
        case true:
            var oldVideoCount = Int()
            oldVideoCount = videos.count
            sendRequest()
            if videos.count > oldVideoCount {
                DispatchQueue.main.async {
                    block(self.videos)
                }
            }
        }
    }
}
