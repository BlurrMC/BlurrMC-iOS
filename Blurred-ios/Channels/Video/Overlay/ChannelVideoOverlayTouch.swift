//
//  ChannelVideoOverlayTouch.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/11/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation
import Valet
import Nuke
import UIKit
import Alamofire

class ChannelVideoOverlayTouch {
    
    // MARK: Like Tap
    @objc func liketapFunction(sender:UITapGestureRecognizer) {
        likeTapFunction()
    }
    
    // MARK: Description Tap
    @objc func descriptiontapFunction(sender:UITapGestureRecognizer) {
        descriptionTap()
    }
    
    // MARK: Check the like count of video and set it
    func checkLikeCount() {
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(videoId).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let likecount = JSON!["likecount"] as? Int else { return }
                DispatchQueue.main.async {
                    self.delegate?.didChangeLikeNumber(self, likeNumber: likecount)
                }
            } catch {
                return
            }
        }
    }
    
    init(videoId:Int) {
        self.videoId = videoId
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
                    DispatchQueue.main.async {
                        self.delegate?.didChangeHeartIcon(self, videoLiked: true)
                    }
                    guard let likeid = JSON!["likeid"] as? Dictionary<String, Any> else { return }
                    guard let id = likeid["id"] as? Int else { return }
                    self.likeId = id
                    self.isVideoLiked = true
                } else if status == "Video has not been liked" {
                    DispatchQueue.main.async {
                        self.delegate?.didChangeHeartIcon(self, videoLiked: false)
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
                        self.delegate?.didChangeHeartIcon(self, videoLiked: true)
                    }
                case "Video has been unliked.":
                    DispatchQueue.main.async {
                        self.delegate?.didChangeHeartIcon(self, videoLiked: false)
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
            DispatchQueue.main.async {
                self.delegate?.didChangeHeartIcon(self, videoLiked: false)
            }
            if likenumber != 0 {
                let subtot = likenumber - 1
                DispatchQueue.main.async {
                    self.delegate?.didChangeLikeNumber(self, likeNumber: subtot)
                }
            }
            sendDeleteLikeRequest()
            isVideoLiked = false
        } else if isVideoLiked == false {
            DispatchQueue.main.async {
                self.delegate?.didChangeHeartIcon(self, videoLiked: true)
            }
            if likenumber != 0 {
                likenumber = likenumber - 1
                let subtot = likenumber + 1
                
                DispatchQueue.main.async {
                    self.delegate?.didChangeLikeNumber(self, likeNumber: subtot)
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
                                
                                   DispatchQueue.main.async {
                                    self.delegate?.didChangeAvatarUrl(self, avatarUrl: railsUrl)
                                   }
                               } catch {
                                   return
                               }
                    }
                    DispatchQueue.main.async {
                        self.delegate?.didChangeDescription(self, definedDescription: descriptionString)
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
    
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Variables
    var delegate: ChannelVideoOverlayTouchUIDelegate?
    var videoId: Int
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
                        self.delegate?.didChangeHeartIcon(self, videoLiked: false)
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
            let newDescription: String = "\(self.publishdate) \n\(viewCount)"
            DispatchQueue.main.async {
                self.delegate?.didChangeDescription(self, definedDescription: newDescription)
            }
            isItSwitched = true
        } else {
            DispatchQueue.main.async {
                self.delegate?.didChangeDescription(self, definedDescription: self.videoDesc)
            }
            isItSwitched = false
        }
    }
}
