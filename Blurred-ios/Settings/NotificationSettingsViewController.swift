//
//  NotificationSettingsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/13/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet
import TTGSnackbar

class NotificationSettingsViewController: UIViewController {
    
    // MARK: Variables
    var followSetting: Bool = true
    var commentSetting: Bool = true
    var likedCommentSetting: Bool = true
    var replySetting: Bool = true
    var likedVideoSetting: Bool = true
    @IBOutlet var notificationSwitches: [UISwitch]!
    @IBOutlet weak var likedVideoNotifications: UISwitch!
    @IBOutlet weak var replyNotifications: UISwitch!
    @IBOutlet weak var likeCommentNotifications: UISwitch!
    @IBOutlet weak var commentNotifications: UISwitch!
    @IBOutlet weak var followNotifications: UISwitch!
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Notification Settings"
        getNotificationSettings()
    }
    
    // MARK: Get user's notifications' settings
    func getNotificationSettings() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        AF.request("https://blurrmc.com/api/v1/notification_settings", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            guard let data = response.data else {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                return
            }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let follow = JSON!["follow"] as? Bool else { return }
                guard let comment = JSON!["comment"] as? Bool else { return }
                guard let likedComment = JSON!["likedcomment"] as? Bool else { return }
                guard let reply = JSON!["reply"] as? Bool else { return }
                guard let likedVideo = JSON!["likedvideo"] as? Bool else { return }
                self.notificationSwitches.forEach({ (notificationSwitch) in
                    DispatchQueue.main.async {
                        notificationSwitch.isEnabled = true
                    }
                })
                
                // Follow
                self.followSetting = follow
                DispatchQueue.main.async {
                    self.followNotifications.isOn = follow
                }
                
                // Comment
                self.commentSetting = comment
                DispatchQueue.main.async {
                    self.commentNotifications.isOn = comment
                }
                
                // Liked comment
                self.likedCommentSetting = likedComment
                DispatchQueue.main.async {
                    self.likeCommentNotifications.isOn = likedComment
                }
                
                // Reply
                self.replySetting = reply
                DispatchQueue.main.async {
                    self.replyNotifications.isOn = reply
                }
                
                // Liked video
                self.likedVideoSetting = likedVideo
                DispatchQueue.main.async {
                    self.likedVideoNotifications.isOn = likedVideo
                }
            } catch {
                let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                print("Error code: asj329ehawudisjk, error: \(error)")
                return
            }
        }
        
    }
    
    // MARK: Notification Network Request (To change the notification's setting)
    func notificationNetworkRequest(controller: String) {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/\(controller)", method: .patch, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let status = JSON!["status"] as? String else { return }
                if status != "Everything set!" {
                    let snackbar = TTGSnackbar(message: "Error changing notification settings.", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                    print("error code: 439a8sf9a8sudfn")
                }
            } catch {
                let snackbar = TTGSnackbar(message: "Error changing notification settings.", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                }
                print("error code: iasdfahsdf4h378qwuae")
            }
        }
    }
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    @IBAction func changedFollowSetting(_ sender: Any) {
        if followSetting == true {
            notificationNetworkRequest(controller: "disablefollownotifications")
        } else {
            notificationNetworkRequest(controller: "enablefollownotifications")
        }
        followSetting = !followSetting
    }
    
    @IBAction func changedCommentSetting(_ sender: Any) {
        if commentSetting == true {
            notificationNetworkRequest(controller: "disablecommentnotifications")
        } else {
            notificationNetworkRequest(controller: "enablecommentnotifications")
        }
        commentSetting = !commentSetting
    }
    
    @IBAction func changedLikedCommmentSetting(_ sender: Any) {
        if likedCommentSetting == true {
            notificationNetworkRequest(controller: "disablelikecommentnotifications")
        } else {
            notificationNetworkRequest(controller: "enablelikecommentnotifications")
        }
        likedCommentSetting = !likedCommentSetting
    }
    
    @IBAction func changedReplySetting(_ sender: Any) {
        if replySetting == true {
            notificationNetworkRequest(controller: "disablereplynotifications")
        } else {
            notificationNetworkRequest(controller: "enablereplynotifications")
        }
        replySetting = !replySetting
    }
    
    @IBAction func changedLikedVideoSetting(_ sender: Any) {
        if likedVideoSetting == true {
            notificationNetworkRequest(controller: "disablelikedvideonotifications")
        } else {
            notificationNetworkRequest(controller: "enablelikedvideonotifications")
        }
        likedVideoSetting = !likedVideoSetting
    }
    
}
