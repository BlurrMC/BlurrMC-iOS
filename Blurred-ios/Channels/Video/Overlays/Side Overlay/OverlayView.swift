//
//  ChannelVideoOverlayViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/8/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke
import Alamofire

class ChannelVideoOverlayView: UIView {
    
    // MARK: Variables
    var newAvatarUrl = String()
    var videoId = String()
    var isVideoLiked = Bool()
    var likenumber = Int()
    var likeId = String()
    var videoUsername = String()
    var videoUrl: URL?
    var name = String()
    var blocked = Bool()
    var channelReported = Bool()
    var videoReported = Bool()
    
    var resizedImageProcessors: [ImageProcessing] {
        let imageSize = CGSize(width: self.videoChannel.frame.width, height: self.videoChannel.frame.height)
        return [ImageProcessors.Resize(size: imageSize, contentMode: .aspectFill)]
    }
    
    // MARK: Delegates
    weak var delegate2: ChannelVideoDescriptionDelegate?
    weak var delegate: ChannelVideoOverlayViewDelegate?
    
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: XIB Name
    let kCONTENT_XIB_NAME = "ChannelVideoOverlay"
    
    // MARK: Update Outlets
    func changeHeartIcon() {
        switch isVideoLiked {
        case true:
            DispatchQueue.main.async {
                UIView.transition(with: self.videoLike, duration: 0.5, options: .transitionFlipFromRight, animations: { self.videoLike.image = UIImage(systemName: "heart.fill") } ,completion: nil)
                self.videoLike.tintColor = UIColor.systemRed
            }
        case false:
            DispatchQueue.main.async {
                UIView.transition(with: self.videoLike, duration: 0.5, options: .transitionFlipFromRight, animations: { self.videoLike.image = UIImage(systemName: "heart") } ,completion: nil)
                self.videoLike.tintColor = UIColor.white
            }
        }
    }
    func changeChannelAvatar() {
        guard let avatarUrl = URL(string: "\(self.newAvatarUrl)") else { return }
        let request = ImageRequest(
          url: avatarUrl,
          processors: resizedImageProcessors)
        let options = ImageLoadingOptions(
          transition: .fadeIn(duration: 0.1)
        )
        DispatchQueue.main.async {
            Nuke.loadImage(with: request, options: options, into: self.videoChannel)
        }
    }
    func changeLikeCount() {
        switch likenumber {
        case _ where likenumber > 1000 && likenumber < 100000:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber/1000).\((self.likenumber/100)%10)k"
            }
        case _ where likenumber > 100000 && likenumber < 1000000:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber/1000)k"
            }
        case _ where likenumber > 1000000 && likenumber < 100000000:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber/1000000).\((self.likenumber/1000)%10)M"
            }
        case _ where likenumber > 100000000:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber/1000000)M"
            }
        case _ where likenumber == 1:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber)"
            }
        default:
            DispatchQueue.main.async {
                self.videoLikeCount.text = "\(self.likenumber)"
            }
        }
    }
    
    // MARK: Initalizing
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)
        contentView.fixInView(self)
        DispatchQueue.global(qos: .background).async {
            self.sendRequest()
            self.sendCheckLikeRequest()
            self.checkLikeCount()
            let tapp = UITapGestureRecognizer(target: self, action: #selector(self.tappFunction))
            let tappp = UITapGestureRecognizer(target: self, action: #selector(self.tapppFunction))
            let liketap = UITapGestureRecognizer(target: self, action: #selector(self.liketapFunction(_:)))
            let shareTap = UITapGestureRecognizer(target: self, action: #selector(self.shareTap(sender:)))
            let reportPress = UILongPressGestureRecognizer(target: self, action: #selector(self.reportPress(sender:)))
            DispatchQueue.main.async {
                self.videoComment.addGestureRecognizer(tappp)
                self.videoChannel.addGestureRecognizer(tapp)
                self.videoLike.addGestureRecognizer(liketap)
                self.videoShare.addGestureRecognizer(shareTap)
                self.videoShare.addGestureRecognizer(reportPress)
            }
            let pipeline = ImagePipeline {
              let dataCache = try? DataCache(name: "com.blurrmc.blurrmc.datacache")
              dataCache?.sizeLimit = 200 * 1024 * 1024
              $0.dataCache = dataCache
            }
            ImagePipeline.shared = pipeline
        }
    }
    
    
    // MARK: Report Press Recognizer
    @objc func reportPress(sender: UILongPressGestureRecognizer) {
        if videoReported {
            self.videoReported = true
            delegate?.didPressReport(videoId: videoId)
        } else {
            guard let videoUrl = self.videoUrl?.absoluteString else { return }
            delegate?.didTapShare(self, videoUrl: videoUrl, videoId: videoId)
        }
    }
    
    
    // MARK: Share Tap Recognizer
    @objc func shareTap(sender:UITapGestureRecognizer) {
        guard let videoUrl = self.videoUrl?.absoluteString else { return }
        delegate?.didTapShare(self, videoUrl: videoUrl, videoId: videoId)
    }
    
    // MARK: Show user channel tap
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        delegate?.didTapChannel(self, videousername: videoUsername, resizedImageProcessor: resizedImageProcessors, isReported: channelReported, isBlocked: blocked, name: name)
    }
    
    // MARK: Show Video Comments Tap
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        delegate?.didTapComments(self, videoid: videoId)
    }
    
    // MARK: Outlets
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var videoShare: UIImageView!
    @IBOutlet weak var videoLikeCount: UILabel!
    @IBOutlet weak var videoLike: UIImageView!
    @IBOutlet weak var videoComment: UIImageView!
    @IBOutlet weak var videoChannel: UIImageView!
    
    // MARK: Like Tap
    @objc func liketapFunction(_ sender:UITapGestureRecognizer) {
        likeTapFunction()
    }
    
    // MARK: Check the like count of video and set it
    func checkLikeCount() {
        AF.request("https://www.blurrmc.com/api/v1/videos/\(videoId).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let likecount = JSON!["likecount"] as? Int else { return }
                self.likenumber = likecount
                DispatchQueue.main.async {
                    self.changeLikeCount()
                }
            } catch {
                return
            }
        }
    }
    
    // MARK: Checks if user liked video
    func sendCheckLikeRequest() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let url = String("https://www.blurrmc.com/api/v1/videos/\(videoId)/didyoulikeit/")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status == "This video is liked." {
                    self.isVideoLiked = true
                    self.changeHeartIcon()
                    guard let likeid = JSON!["likeid"] as? Dictionary<String, Any> else { return }
                    guard let id = likeid["id"] as? String else { return }
                    self.likeId = id
                } else if status == "Video has not been liked" {
                    self.isVideoLiked = false
                    self.changeHeartIcon()
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
    
    // MARK: Sends request to like the video
    func sendLikeRequest() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("https://www.blurrmc.com/api/v1/videos/\(videoId)/apilikes/")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                switch status {
                case "You have already liked it!":
                    self.sendDeleteLikeRequest()
                case "Video has been liked":
                    self.isVideoLiked = true
                    self.changeHeartIcon()
                case "Video has been unliked.":
                    self.isVideoLiked = false
                    self.changeHeartIcon()
                case .none:
                    break
                case .some(_):
                    break
                }
                self.checkLikeCount()
                self.sendCheckLikeRequest()
            } catch {
                print(error)
                print("error code: 1972026583")
                return
            }
        }
    }
    
    // MARK: Tap function for like
    func likeTapFunction() {
        let throttler = Throttler(minimumDelay: 5)
        if isVideoLiked == true {
            isVideoLiked = false
            self.changeHeartIcon()
            if self.likenumber != 0 {
                let subtot = self.likenumber - 1
                self.likenumber = subtot
                self.changeLikeCount()
            }
            throttler.throttle( {
                self.sendDeleteLikeRequest()
            }, uniqueId: nil)
        } else if isVideoLiked == false {
            isVideoLiked = true
            self.changeHeartIcon()
            let subtot = likenumber + 1
            likenumber = subtot
            self.changeLikeCount()
            throttler.throttle( {
                self.sendLikeRequest()
            }, uniqueId: nil)
        }
    }
    
    // MARK: Send request for video info
    func sendRequest() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let myUrl = URL(string: "https://www.blurrmc.com/api/v1/videos/\(videoId).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        AF.request("https://www.blurrmc.com/api/v1/videos/\(videoId).json", method: .get, headers: headers).responseJSON { response in
            guard let response = response.data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: response, options: .mutableContainers) as? NSDictionary {
                    guard let publishDate: String = json["publishdate"] as? String else { return }
                    guard let viewCount: Int = json["viewcount"] as? Int else { return }
                    guard let descriptionString: String = json["description"] as? String else { return }
                    guard let username: String = json["username"] as? String else { return }
                    guard let videoReported: Bool = json["reported"] as? Bool else { return }
                    self.videoReported = videoReported
                    self.videoUsername = username
                    AF.request("https://www.blurrmc.com/api/v1/channels/\(String(describing: username)).json", headers: headers).responseJSON {   response in
                        guard let response = response.data else { return }
                        var JSON: [String: Any]?
                        do {
                            JSON = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any]
                            let avatarUrl = JSON!["avatar_url"] as? String
                            let railsUrl = String("https://www.blurrmc.com\(avatarUrl!)")
                            self.newAvatarUrl = railsUrl
                            self.changeChannelAvatar()
                            guard let name = JSON!["name"] as? String else { return }
                            guard let isBlocked = JSON!["isblocked"] as? Bool else { return }
                            guard let channelReported = JSON!["reported"] as? Bool else { return }
                            self.name = name
                            self.blocked = isBlocked
                            self.channelReported = channelReported
                        } catch {
                            return
                        }
                    }
                    self.delegate2?.didReceiveInfo(self, views: viewCount, description: descriptionString, publishdate: publishDate)
                }
            } catch {
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
        let url = String("https://www.blurrmc.com/api/v1/videos/\(videoId)/apilikes/\(likeId)")
        AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Video has been unliked." && status == "You have not liked this!" {
                    self.sendLikeRequest()
                } else if status == "Video has been unliked." {
                    self.isVideoLiked = false
                    self.changeHeartIcon()
                }
                self.checkLikeCount()
                self.sendCheckLikeRequest()
            } catch {
                print("error code: 1972026583")
                return
            }
        }
    }
    
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }

}
