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
    var videoId = Int()
    var isVideoLiked = Bool()
    var likenumber = Int()
    var isItSwitched = Bool()
    var publishdate = String()
    var views = Int()
    var videoDesc = String()
    var likeId = Int()
    var videoUsername = String()
    var definedDescription = String()
    var viewCount = String()
    weak var delegate: ChannelVideoOverlayViewDelegate?
    
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Lets
    let kCONTENT_XIB_NAME = "ChannelVideoOverlay"
    
    // MARK: Update Outlets
    // Must be called by main thread
    func updateDescription() {
        if isItSwitched == true {
            videoDescription.text = String("\(publishdate) \n\(viewCount)")
        } else {
            videoDescription.text = definedDescription
        }
        
    }
    func changeHeartIcon() {
        if isVideoLiked == true {
            videoLike.image = UIImage(systemName: "heart.fill")
            videoLike.tintColor = UIColor.systemRed
        } else {
            videoLike.image = UIImage(systemName: "heart")
            videoLike.tintColor = UIColor.lightGray
        }
    }
    func changeChannelAvatar() {
        guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {
            return
        }
        let avatarUrl = URL(string: "\(self.newAvatarUrl)")
        Nuke.loadImage(with: avatarUrl ?? imageURL, into: videoChannel)
    }
    func changeLikeCount() {
        switch likenumber {
        case _ where likenumber > 1000 && likenumber < 100000:
            self.videoLikeCount.text = "\(self.likenumber/1000).\((self.likenumber/100)%10)k"
        case _ where likenumber > 100000 && likenumber < 1000000:
            self.videoLikeCount.text = "\(self.likenumber/1000)k"
        case _ where likenumber > 1000000 && likenumber < 100000000:
            self.videoLikeCount.text = "\(self.likenumber/1000000).\((self.likenumber/1000)%10)M"
        case _ where likenumber > 100000000:
            self.videoLikeCount.text = "\(self.likenumber/1000000)M"
        case _ where likenumber == 1:
            self.videoLikeCount.text = "\(self.likenumber)"
        default:
            self.videoLikeCount.text = "\(self.likenumber)"
        }
    }
    
    @IBOutlet var contentView: UIView!
    
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
            let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(self.descriptiontapFunction(_:)))
            DispatchQueue.main.async {
                self.videoDescription.addGestureRecognizer(descriptiontap)
                self.videoComment.addGestureRecognizer(tappp)
                self.videoChannel.addGestureRecognizer(tapp)
                self.videoLike.addGestureRecognizer(liketap)
            }
        }
    }
    
    // MARK: Show user channel tap
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        delegate?.didTapChannel(self, videousername: videoUsername)
    }
    
    // MARK: Show Video Comments Tap
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        delegate?.didTapComments(self, videoid: videoId)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Outlets
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet weak var videoShare: UIImageView!
    @IBOutlet weak var videoLikeCount: UILabel!
    @IBOutlet weak var videoLike: UIImageView!
    @IBOutlet weak var videoComment: UIImageView!
    @IBOutlet weak var videoChannel: UIImageView!
    
    // MARK: Like Tap
    @objc func liketapFunction(_ sender:UITapGestureRecognizer) {
        likeTapFunction()
    }
    
    // MARK: Description Tap
    @objc func descriptiontapFunction(_ sender:UITapGestureRecognizer) {
        descriptionTap()
    }
    
    // MARK: Check the like count of video and set it
    func checkLikeCount() {
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(videoId).json").responseJSON { response in
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
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/didyoulikeit/")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status == "This video is liked." {
                    self.isVideoLiked = true
                    DispatchQueue.main.async {
                        self.changeHeartIcon()
                    }
                    guard let likeid = JSON!["likeid"] as? Dictionary<String, Any> else { return }
                    guard let id = likeid["id"] as? Int else { return }
                    self.likeId = id
                } else if status == "Video has not been liked" {
                    self.isVideoLiked = false
                    DispatchQueue.main.async {
                        self.changeHeartIcon()
                    }
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
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/apilikes/")
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
                    DispatchQueue.main.async {
                        self.changeHeartIcon()
                    }
                case "Video has been unliked.":
                    self.isVideoLiked = false
                    DispatchQueue.main.async {
                        self.changeHeartIcon()
                    }
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
        if isVideoLiked == true {
            isVideoLiked = false
            DispatchQueue.main.async {
                self.changeHeartIcon()
            }
            if likenumber != 0 {
                let subtot = likenumber - 1
                likenumber = subtot
                DispatchQueue.main.async {
                    self.changeLikeCount()
                }
            }
            sendDeleteLikeRequest()
            isVideoLiked = false
        } else if isVideoLiked == false {
            isVideoLiked = true
            DispatchQueue.main.async {
                self.changeHeartIcon()
            }
            if likenumber != 0 {
                likenumber = likenumber - 1
                let subtot = likenumber + 1
                likenumber = subtot
                DispatchQueue.main.async {
                    self.changeLikeCount()
                }
            }
            sendLikeRequest()
            isVideoLiked = true
        }
    }
    
    // MARK: Send request for video info
    func sendRequest() {
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(videoId).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print("error code: 1kf01k3-2")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    guard let publishDate: String = parseJSON["publishdate"] as? String else { return }
                    guard let viewCount: Int = parseJSON["viewcount"] as? Int else { return }
                    guard let descriptionString: String = parseJSON["description"] as? String else { return }
                    guard let username: String = parseJSON["username"] as? String else { return }
                    self.videoUsername = username
                    self.views = viewCount
                    self.publishdate = publishDate
                    self.videoDesc = descriptionString
                    AF.request("http://10.0.0.2:3000/api/v1/channels/\(String(describing: username)).json").responseJSON {   response in
                               var JSON: [String: Any]?
                               do {
                                   JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                                   let avatarUrl = JSON!["avatar_url"] as? String
                                   let railsUrl = String("http://10.0.0.2:3000\(avatarUrl!)")
                                self.newAvatarUrl = railsUrl
                                   DispatchQueue.main.async {
                                    self.changeChannelAvatar()
                                   }
                               } catch {
                                   return
                               }
                    }
                    self.definedDescription = descriptionString
                    DispatchQueue.main.async {
                        self.updateDescription()
                    }
                } else {
                    print("error: \(String(describing: error)) Error code: 1jfnt04l2-2")
                    return
                }
            } catch {
                print("error:\(error) Error code: amr031k102-2")
                return
            }
        }
        task.resume()
    }
    
    // MARK: Delete's the like
    func sendDeleteLikeRequest() {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/apilikes/\(likeId)")
        AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Video has been unliked." && status == "You have not liked this!" {
                    self.sendLikeRequest()
                } else if status == "Video has been unliked." {
                    self.isVideoLiked = false
                    DispatchQueue.main.async {
                        self.changeHeartIcon()
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
    // MARK: Video views + publish date
    func descriptionTap() {
        if isItSwitched == false {
            switch views {
            case _ where views > 1000 && views < 100000:
                self.viewCount = "\(self.views/1000).\((self.views/100)%10)k Views"
            case _ where views > 100000 && views < 1000000:
                self.viewCount = "\(self.views/1000)k Views "
            case _ where views > 1000000 && views < 100000000:
                self.viewCount = "\(self.views/1000000).\((self.views/1000)%10)M Views"
            case _ where views > 100000000:
                self.viewCount = "\(self.views/1000000)M Views"
            case _ where views == 1:
                self.viewCount = "\(self.views) View"
            default:
                self.viewCount = "\(self.views) Views"
            }
            isItSwitched = true
            DispatchQueue.main.async {
                self.updateDescription()
            }
        } else {
            definedDescription = videoDesc
            isItSwitched = false
            DispatchQueue.main.async {
                self.updateDescription()
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
