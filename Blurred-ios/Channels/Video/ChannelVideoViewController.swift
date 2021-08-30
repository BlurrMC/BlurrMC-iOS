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
import Nuke
import TTGSnackbar

class ChannelVideoViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate, ChannelVideoOverlayViewDelegate {
    
    
    // MARK: Alert from delegate
    func willPresentAlert(alertController: UIAlertController) {
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Did press report
    func didPressReport(videoId: String, videoIndex: IndexPath) {
        popupMessages().showMessageWithOptions(title: "Hey!", message: "Are you sure that you would like to report this video?", firstOptionTitle: "Yes", secondOptionTitle: "Nahhhh", viewController: self, {
            guard let token: String = try? self.tokenValet.string(forKey: "Token") else { return }
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ]
            let params = [
                "video_id": videoId
            ]
            DispatchQueue.main.async {
                self.tableNode.deleteRows(at: [videoIndex], with: .automatic)
            }
            self.videos.remove(at: videoIndex.row)
            AF.request("https://blurrmc.com/api/v1/reports", method: .post, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
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
    
    var resizedImageProcessors = [ImageProcessing]()
    
    // MARK: From delegate, for sharing
    func didTapShare(_ view: ChannelVideoOverlayView, videoUrl: String, videoId: String) {
        shareWindow(videoUrl: videoUrl, videoId: videoId)
    }

    // MARK: Tap for channel from overlay
    func didTapChannel(_ view: ChannelVideoOverlayView, videousername: String, resizedImageProcessor: [ImageProcessing], isReported: Bool, isBlocked: Bool, name: String) {
        self.reported = isReported
        self.blocked = isBlocked
        self.name = name
        self.resizedImageProcessors = resizedImageProcessor
        showUserChannel(videoUsername: videousername)
    }
    
    // MARK: Tap for comments from overlay
    func didTapComments(_ view: ChannelVideoOverlayView, videoid: String) {
        showVideoComments(videoId: videoid)
    }
    
    // MARK: Variables
    var tableNode: ASTableNode!
    var lastNode: ChannelVideoCellNode?
    private var videos = [Video]()
    var videoUsername = String()
    var rowNumber = Int()
    var videoString = String()
    var videoUrlString = String()
    var isItFromSearch = Bool()
    var videoId = String()
    var channelId = String()
    var reported = Bool()
    var blocked = Bool()
    var name = String()
    var shouldBatchFetch: Bool = true
    var oldVideoCount = Int()
    var currentPage: Int = 1
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
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
                    // Response to comment: Backup method? Are you serious? Eh, whatever
                    let videoToShare = [ URL(string: "https://blurrmc.com/videos/\(videoId)") ]
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
    
    // MARK: Request for specific video
    func sendRequest() {
        let myUrl = URL(string: "https://blurrmc.com/api/v1/videos/\(videoString).json")
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
                vc.resizedImageProcessors = self.resizedImageProcessors
                vc.channelUsername = videoUsername
                vc.segueUsername = videoUsername
                vc.segueName = name
                vc.isReported = reported
            }
        }
    }
    
    // MARK: Videos
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    
    class Video: Codable {
        let videourl: String
        let videoid: String
        let reported: Bool
        init(videourl: String, videoid: String, reported: Bool) {
            self.videourl = videourl
            self.videoid = videoid
            self.reported = reported
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
    func showVideoComments(videoId: String) {
        self.videoId = videoId
        self.performSegue(withIdentifier: "showComments", sender: self)
        
    }
    
    // MARK: Download channel videos
    func channelVideoIds() {
        guard let token: String = try? self.tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/channelvideos/\(channelId).json", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                self.videos = downloadedVideo.videos
                let pathTotRow = IndexPath.init(row: self.rowNumber, section: 0)
                DispatchQueue.main.async {
                    self.tableNode.reloadData()
                    self.tableNode.scrollToRow(at: pathTotRow, at: .none, animated: true)
                }
            } catch {
                print("error code: 1kzka0aww3-2, controller: channelvideoview, error: \(error)")
                print("\(self.channelId)")
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
        self.tableNode.insertRows(at: indexPaths, with: .none)
    }
    
    // MARK: Batch Fetch Request
    func batchFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/channelvideos/\(channelId)", method: .post, parameters: parameters, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                success(response)
            case .failure(let error):
                failure(error as NSError)
            }
            
        }
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
            let videoUrl = URL(string: videourll)
            return {
                let node = ChannelVideoCellNode(with: videoUrl!, videoId: videoId, doesParentHaveTabBar: false, firstVideo: false, indexPath: indexPath, reported: self.videos[indexPath.row].reported)
                node.delegate = self
                node.debugName = "\(self.videos[indexPath.row].videoid)"
                return node
            }
        } else {
            let url = URL(string: videoUrlString)!
            return {
                let node = ChannelVideoCellNode(with: url, videoId: self.videoString, doesParentHaveTabBar: false, firstVideo: false, indexPath: indexPath, reported: self.videos[indexPath.row].reported)
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
        return shouldBatchFetch
    }
    
    // MARK: Batch fetch function
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        oldVideoCount = self.videos.count
        currentPage = currentPage + 1
        self.batchFetch(success: {(response) -> Void in
            guard let data = response?.data else {
                print("error code: asdf23ruewifad")
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
                print("error code: tn5brtygs, controller: channel video, error: \(error)")
                return
            }
        }, failure: { (error) -> Void in
            print("error code: saaf")
            print(error as Any)
        })
        
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
