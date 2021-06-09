//
//  NotificationsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Alamofire
import Nuke


class NotificationsViewController: UIViewController {
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    // MARK: Mark notifications as read
    func markAsRead() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/notifications/mark_as_read", method: .post, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: 34nf9adsi")
                return
            }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                switch status {
                case "success":
                    return
                case .none:
                    print("error code: a04mv9rema, error: There is no status, this typically happens if the user has no notifications, where: marking notifications as read")
                case .some(_):
                    print("error code: 1kc0t-3ma")
                }
            } catch {
                print("error code: avo0trsn")
                return
            }
        }
    }
    
    
    // MARK: Segue Lifecycle
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            guard let json = convertStringToDictionary(text: notifications[indexPath.row].template) else { return }
            switch notifications[indexPath.row].action {
            case "liked":
                if let vc = segue.destination as? ChannelVideoViewController {
                    guard let videoId = json["video"] as? String else { return }
                    vc.isItFromSearch = true
                    vc.videoString = videoId
                }
            case "followed":
                if let vc = segue.destination as? OtherChannelViewController {
                    guard let follower = json["follower"] as? String else { return }
                    vc.chanelVar = follower
                }
            case "Commented":
                if let vc = segue.destination as? ChannelVideoViewController {
                    guard let video = json["video"] as? String else { return }
                    vc.isItFromSearch = true
                    vc.videoString = video
                    // WHY is this named videoString when its AN INTEGER?!?!?!?!?!?!
                    // ^ Old comment, this is now fixed with uuids (well, it could be called videoUUID but eh) :)
                }
            case "Replied":
                if let vc = segue.destination as? ChannelVideoViewController {
                    guard let video = json["video"] as? String else { return }
                    vc.isItFromSearch = true
                    vc.videoString = video
                }
            case "Liked comment":
                if let vc = segue.destination as? ChannelVideoViewController {
                    guard let video = json["video"] as? String else { return }
                    vc.isItFromSearch = true
                    vc.videoString = video
                }
            default:
                break
            }
        }
    }
    
    
    // MARK: Convert String To Dictionary
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("error code: 19med01mr")
            }
        }
        return nil
    }
    
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    private let refreshControl = UIRefreshControl()
    private var notifications = [Notification]()
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: Get the notifications
    func getNotifications() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/notifications.json", method: .get, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: 1kdmg03l10")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedNotifications = try decoder.decode(Notifications.self, from: data)
                self.notifications = downloadedNotifications.notifications
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("error code: f02mf0al0, error: could not decode notifications from api (may happen if user has no notifications), actual error: \(error)")
                return
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        markAsRead()
        // Maybe put getNotifications() here ????
        /// No
    }
    
    // MARK: Classes
    class Notifications: Codable {
        let notifications: [Notification]
        init(notifications: [Notification]) {
            self.notifications = notifications
        }
    }
    class Notification: Codable {
        let unread: Bool
        let template: String
        let action: String
        init(unread: Bool, template: String, action: String) {
            self.unread = unread
            self.template = template
            self.action = action
        }
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        getNotifications()
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.isUserInteractionEnabled = true
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        generator.prepare()
        self.navigationItem.title = "Notifications"
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
            self.tableView.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
            self.tableView.backgroundColor = UIColor(hexString: "#141414")
        }
    }
    
    @objc func refreshNotifications() {
        getNotifications()
        generator.impactOccurred()
    }
    
}
extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch notifications[indexPath.row].action {
        case "liked":
            self.performSegue(withIdentifier: "showNotificationVideo", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        case "followed":
            self.performSegue(withIdentifier: "showNotificationChannel", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        case "Commented":
            self.performSegue(withIdentifier: "showNotificationVideo", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        case "Replied":
            self.performSegue(withIdentifier: "showNotificationVideo", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        case "Liked comment":
            self.performSegue(withIdentifier: "showNotificationVideo", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            print("error code: alb04msi")
            break
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsTableViewCell") as? NotificationsTableViewCell else { return UITableViewCell() }
        switch notifications[indexPath.row].unread {
        case true:
            DispatchQueue.main.async {
                cell.unreadBubble.image = UIImage(systemName: "circle")
            }
        case false:
            DispatchQueue.main.async {
                cell.unreadBubble.image = nil
            }
        }
        let json = convertStringToDictionary(text: notifications[indexPath.row].template)
        if let parseJSON = json {
            switch notifications[indexPath.row].action {
            case "liked":
                guard let videoId = parseJSON["video"] as? String else { return cell }
                guard let liker = parseJSON["liker"] as? String else { return cell }
                let description = String("\(liker) liked your video.")
                DispatchQueue.main.async {
                    cell.notificationDescription.text = description
                    
                }
                AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(videoId)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
                    guard let data = response.data else { return }
                    do {
                        guard let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                        guard let thumbnail = JSON["thumbnail_url"] as? String else { return }
                        guard let thumbnailUrl = URL(string: thumbnail) else { return }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: thumbnailUrl, into: cell.thumbnailView)
                        }
                    } catch {
                        print("error code: maj52kamv3")
                        return
                    }
                }
            case "followed":
                guard let follower = parseJSON["follower"] as? String else { return UITableViewCell() }
                let description = String("\(follower) followed you!")
                DispatchQueue.main.async {
                    cell.notificationDescription.text = description
                }
                AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(follower)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
                    do {
                        guard let JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any] else { return }
                        let avatarUrl = JSON["avatar_url"] as? String
                        guard let url = URL(string: "https://www.bartenderdogseatmuffins.xyz\(avatarUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: url, into: cell.thumbnailView)
                            cell.thumbnailView.layer.cornerRadius = 35
                        }
                    } catch {
                        print("error code: maj52kamv3")
                        return
                    }
                }
            case "Commented":
                guard let video = parseJSON["video"] as? String else { return UITableViewCell() }
                guard let user = parseJSON["user"] as? String else { return UITableViewCell() }
                guard let comment = parseJSON["comment"] as? String else { return UITableViewCell() }
                let description = "@" + user + " commented, " + comment + ", on your video."
                DispatchQueue.main.async {
                    cell.notificationDescription.text = description
                }
                AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(video)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
                    guard let data = response.data else { return }
                    do {
                        guard let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                        guard let thumbnail = JSON["thumbnail_url"] as? String else { return }
                        guard let thumbnailUrl = URL(string: thumbnail) else { return }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: thumbnailUrl, into: cell.thumbnailView)
                        }
                    } catch {
                        print("error code: 42069hahah, error: failed parsing thumbnail, actual error: \(error)")
                        return
                    }
                }
            case "Replied":
                guard let video = parseJSON["video"] as? String else { return UITableViewCell() }
                guard let user = parseJSON["user"] as? String else { return UITableViewCell() }
                guard let reply = parseJSON["reply"] as? String else { return UITableViewCell() }
                let description = "@" + user + " replied to your commenting saying, " + reply
                DispatchQueue.main.async {
                    cell.notificationDescription.text = description
                }
                AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(video)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
                    guard let data = response.data else { return }
                    do {
                        guard let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                        guard let thumbnail = JSON["thumbnail_url"] as? String else { return }
                        guard let thumbnailUrl = URL(string: thumbnail) else { return }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: thumbnailUrl, into: cell.thumbnailView)
                        }
                    } catch {
                        print("error code: asdf0asfasdf32, error: failed parsing thumbnail, actual error: \(error)")
                        return
                    }
                }
            case "Liked comment":
                guard let video = parseJSON["video"] as? String else { return UITableViewCell() }
                guard let user = parseJSON["user"] as? String else { return UITableViewCell() }
                guard let comment = parseJSON["comment"] as? String else { return UITableViewCell() }
                let description = "@" + user + "liked your comment, " + comment
                DispatchQueue.main.async {
                    cell.notificationDescription.text = description
                }
                AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(video)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
                    guard let data = response.data else { return }
                    do {
                        guard let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                        guard let thumbnail = JSON["thumbnail_url"] as? String else { return }
                        guard let thumbnailUrl = URL(string: thumbnail) else { return }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: thumbnailUrl, into: cell.thumbnailView)
                        }
                    } catch {
                        print("error code: 1c2r298jaads, error: failed parsing thumbnail, actual error: \(error)")
                        return
                    }
                }
            default:
                break
            }
        }
        return cell
    }
    
    
}

