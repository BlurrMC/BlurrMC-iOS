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
import UIKit

// MARK: Change this to UIView
class ChannelVideoOverlayView: UIView {
    
    let kCONTENT_XIB_NAME = "ChannelVideoOverlay"
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
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tapppFunction))
        let liketap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoOverlayView.liketapFunction))
        let sharetap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.sharetapFunction))
        let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoOverlayView.descriptiontapFunction))
        videoDescription.addGestureRecognizer(descriptiontap)
        videoShare.addGestureRecognizer(sharetap)
        videoComment.addGestureRecognizer(tappp)
        videoChannel.addGestureRecognizer(tapp)
        videoLike.addGestureRecognizer(liketap)
        /*videoDescription.fixInView(self)
        videoLike.fixInView(self)
        videoLikeCount.fixInView(self)
        videoComment.fixInView(self)
        videoShare.fixInView(self)
        videoChannel.fixInView(self)*/
    }
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Variables
    var videoId = Int()
    var videoUrl = String() // MARK: Not currently in use.
    var isDismissed = Bool()
    var isVideoLiked = Bool()
    var likenumber = Int()
    var isItSwitched = Bool()
    var publishdate = String()
    var views = Int()
    var videoDesc = String()
    var likeId = Int()
    var videoUsername = String()
    
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
                    let descriptionString: String? = parseJSON["description"] as? String
                    guard let username: String = parseJSON["username"] as? String else { return }
                    self.videoUsername = username
                    self.views = viewCount
                    self.publishdate = publishDate
                    self.videoDesc = descriptionString ?? ""
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
                                        Nuke.loadImage(with: railsUrl ?? imageURL, into: self.videoChannel)
                                   }
                               } catch {
                                   return
                               }
                    }
                    DispatchQueue.main.async {
                        self.videoDescription.text = descriptionString
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
    
    /*
    init(Id: Int, videoUrl: URL) {
        self.videoId = Id
        self.videoUrl = videoUrl
        super.init(frame: UIScreen.main.bounds)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented"); }*/
    
    // MARK: Outlets
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet weak var videoShare: UIImageView!
    @IBOutlet weak var videoLikeCount: UILabel!
    @IBOutlet weak var videoLike: UIImageView!
    @IBOutlet weak var videoComment: UIImageView!
    @IBOutlet weak var videoChannel: UIImageView!
    
    // MARK: Tap function for like
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
                    self.videoLikeCount.text = subby
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
                    self.videoLikeCount.text = subby
                }
            }
            sendLikeRequest()
            isVideoLiked = true
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
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart.fill")
                        self.videoLike.tintColor = UIColor.systemRed
                    }
                case "Video has been unliked.":
                    DispatchQueue.main.async {
                        self.videoLike.image = UIImage(systemName: "heart")
                        self.videoLike.tintColor = UIColor.lightGray
                    }
                case .none:
                    break
                case .some(_):
                    break
                }
                self.checkLikeCount()
                self.sendCheckLikeRequest()
            } catch {
                print("error code: 1972026583")
                return
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
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/didyoulikeit/")
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
    
    // MARK: Check the like count of video and set it
    func checkLikeCount() {
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(videoId).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let likecount = JSON!["likecount"] as? Int else { return }
                switch likecount {
                case _ where likecount > 1000 && likecount < 100000:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount/1000).\((likecount/100)%10)k"
                    }
                case _ where likecount > 100000 && likecount < 1000000:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount/1000)k"
                    }
                case _ where likecount > 1000000 && likecount < 100000000:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount/1000000).\((likecount/1000)%10)M"
                    }
                case _ where likecount > 100000000:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount/1000000)M"
                    }
                case _ where likecount == 1:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount)"
                    }
                default:
                    DispatchQueue.main.async {
                        self.videoLikeCount.text = "\(likecount)"
                    }
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
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/apilikes/\(likeId)")
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
                self.videoDescription.text = newDescription
            }
            isItSwitched = true
        } else if isItSwitched == true {
            DispatchQueue.main.async {
                self.videoDescription.text = self.videoDesc
            }
            isItSwitched = false
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
