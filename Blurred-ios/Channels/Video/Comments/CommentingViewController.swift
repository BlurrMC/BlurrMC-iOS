//
//  CommentingViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 7/11/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Nuke
import Alamofire
import Valet

class CommentingViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Variables
    private var comments = [Comment]()
    var videoId = Int()
    
    
    // MARK: Outlets
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    
    // MARK: Get the user's avatar
    func getAvatar() {
        let userId: String?  = try? myValet.string(forKey: "Id")
        AF.request("http://10.0.0.2:3000/api/v1/channels/\(userId!).json").responseJSON { response in
                   var JSON: [String: Any]?
                   do {
                       JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                       let imageUrl = JSON!["avatar_url"] as? String
                       let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl!)")
                    guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else { return }
                       DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl ?? imageURL, into: self.userAvatar)
                       }
                   } catch {
                       return
                   }
        }
    }
    
    
    // MARK: Text Field Should Return (Send Button)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == commentField {
            textField.resignFirstResponder()
            submitComment()
            downloadJson()
        }
        return true
    }
    
    
    // MARK: Received Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Submit the user's comment
    func submitComment() {
        // Add edit function so you can edit it if is your (and remove it) and if it isn't yours then you can report the comment.
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let token: String? = try? tokenValet.string(forKey: "Token")
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(videoId)/comments/")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        if commentField?.text?.isEmpty != true {
            let comment = commentField.text
            let patchString = ["comment": ["body": comment]]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                return
            }
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    print("error=\(String(describing: error))")
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let parseJSON = json {
                        let returnCode = parseJSON["status"] as? String
                        if returnCode != String("Comment has been made") {
                            return
                        }
                    } else {
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        print(error ?? "No error")
                    }
                } catch {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.showMessage(title: "Error", message: "Error contacting the server. Try again later.", alertActionTitle: "OK")
                    print(error)
                }
            }
            task.resume()
        } else {
            self.showMessage(title: "Alert", message: "Your comment is empty. Please fill it.", alertActionTitle: "OK")
        }
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    
    
    // MARK: Comments Gotten From JSON
    struct Comments: Codable {
        let comments: [Comment]
        init(comments: [Comment]) {
            self.comments = comments
        }
    }
    struct Comment: Codable {
        let created_by: String
        var likes: Int
        let id: Int
        let reply: Bool
        let time_since_creation: String
        let body: String
        var liked: Bool
        let parent_id: Int
        let replies: [Comment]?
        var opened: Bool? = false
        var likeId: Int?
        init(created_by: String, likes: Int, body: String, id: Int, reply: Bool, time_since_creation: String, liked: Bool, parent_id: Int, replies: [Comment], likeId: Int) {
            self.id = id
            self.reply = reply
            self.time_since_creation = time_since_creation
            self.created_by = created_by
            self.likes = likes
            self.body = body
            self.liked = liked
            if parent_id != id {
                self.parent_id = parent_id
            } else {
                self.parent_id = 0
            }
            self.replies = replies
            self.likeId = likeId
        }
    }
    
    // MARK: Download the comments
    func downloadJson() { // Still not done we need to add the user's butt image
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("http://10.0.0.2:3000/api/v1/videos/\(videoId)/comments/", method: .get, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: coi329fj482")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedComments = try decoder.decode(Comments.self, from: data)
                self.comments = downloadedComments.comments
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("error code: f0bm39fna9319g427hf42")
                return
            }
        }
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        commentField?.delegate = self
        downloadJson()
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getAvatar()
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    

}
extension CommentingViewController: CommentCellDelegate {
    func likeButtonTapped(commentId: Int, indexPath: IndexPath, reply: Bool) {
        switch reply {
        case true:
            guard let reply = comments[indexPath.section].replies?[indexPath.row - 1] else { return }
            like(alreadyLiked: reply.liked, cell: reply, likes: reply.likes, indexPath: indexPath, reply: true)
        case false:
            let comment = comments[indexPath.section]
            like(alreadyLiked: comment.liked, cell: comment, likes: comment.likes, indexPath: indexPath, reply: false)
        }
    }
    
    // MARK: Change The Like Count
    func changeLikeCount(likeNumber: Int, indexPath: IndexPath, reply: Bool) {
        switch reply {
        case true:
            let cell = tableView.cellForRow(at: indexPath) as? ReplyTableViewCell
            switch likeNumber {
            case _ where likeNumber > 1000 && likeNumber < 100000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000).\((likeNumber/100)%10)k"
                }
            case _ where likeNumber > 100000 && likeNumber < 1000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000)k"
                }
            case _ where likeNumber > 1000000 && likeNumber < 100000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000000).\((likeNumber/1000)%10)M"
                }
            case _ where likeNumber > 100000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000000)M"
                }
            case _ where likeNumber == 1:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber)"
                }
            default:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber)"
                }
            }
        case false:
            let cell = tableView.cellForRow(at: indexPath) as? CommentCell
            switch likeNumber {
            case _ where likeNumber > 1000 && likeNumber < 100000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000).\((likeNumber/100)%10)k"
                }
            case _ where likeNumber > 100000 && likeNumber < 1000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000)k"
                }
            case _ where likeNumber > 1000000 && likeNumber < 100000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000000).\((likeNumber/1000)%10)M"
                }
            case _ where likeNumber > 100000000:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber/1000000)M"
                }
            case _ where likeNumber == 1:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber)"
                }
            default:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber)"
                }
            }
        }
        
    }
    
    // MARK: Unlike Video
    func sendDeleteLikeRequest(likeid: Int?, commentId: Int, cell: Comment, indexPath: IndexPath, reply: Bool) {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        
        if likeid != nil {
            let url = "http://10.0.0.2:3000/api/v1/videos/\(videoId)/commentlikes/\(commentId)/\(String(describing: likeid))"
            AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let status = JSON!["status"] as? String
                    if status != "Video has been unliked." && status == "You have not liked this!" {
                        self.sendLikeRequest(commentId: commentId, cell: cell, indexPath: indexPath, reply: reply)
                    } else if status == "Video has been unliked." {
                        switch reply {
                        case true:
                            let reply = indexPath.row - 1
                            self.comments[reply].liked = false
                            self.comments[reply].likeId = 0
                        case false:
                            let comment = indexPath.section
                            self.comments[comment].liked = false
                            self.comments[comment].likeId = 0
                        }
                        
                    }
                } catch {
                    print("error code: 0fnboglap139gnza")
                    return
                }
            }
        }
        
    }
    
    
    // MARK: Like the comment
    func sendLikeRequest(commentId: Int, cell: Comment, indexPath: IndexPath, reply: Bool) {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/videos/\(videoId)/comments/\(commentId)")
        AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                switch status {
                case "You have already liked it!":
                    let likeid = JSON!["likeid"] as? Int
                    self.sendDeleteLikeRequest(likeid: likeid, commentId: commentId, cell: cell, indexPath: indexPath, reply: reply)
                case "Video has been liked":
                    let likeid = JSON!["likeid"] as? Int
                    switch reply {
                    case true:
                        let reply = indexPath.row - 1
                        self.comments[reply].liked = true
                        self.comments[reply].likeId = likeid
                    case false:
                        let comment = indexPath.section
                        self.comments[comment].liked = true
                        self.comments[comment].likeId = likeid
                    }
                    
                    self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: true)
                case "Video has been unliked.":
                    switch reply {
                    case true:
                        let reply = indexPath.row - 1
                        self.comments[reply].liked = false
                        self.comments[reply].likeId = 0
                    case false:
                        let comment = indexPath.section
                        self.comments[comment].liked = false
                        self.comments[comment].likeId = 0
                    }
                    
                    self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: false)
                case .none:
                    break
                case .some(_):
                    break
                }
            } catch {
                print(error)
                print("error code: 1972026583")
                return
            }
        }
    }
    
    
    // MARK: Like Tapped (For Delegate)
    func like(alreadyLiked: Bool, cell: Comment, likes: Int, indexPath: IndexPath, reply: Bool) {
        let throttler = Throttler(minimumDelay: 5)
        if alreadyLiked == true {
            switch reply {
            case true:
                comments[indexPath.row - 1].liked = false
            case false:
                comments[indexPath.section].liked = false
            }
            
            self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: alreadyLiked)
            if cell.likes != 0 {
                let subtot = cell.likes - 1
                switch reply {
                case true:
                    comments[indexPath.row - 1].likes = subtot
                case false:
                    comments[indexPath.section].likes = subtot
                }
                
                self.changeLikeCount(likeNumber: likes, indexPath: indexPath, reply: reply)
            }
            throttler.throttle {
                switch reply {
                case true:
                    let reply = indexPath.row - 1
                    self.sendDeleteLikeRequest(likeid: self.comments[reply].likeId, commentId: self.comments[reply].id, cell: cell, indexPath: indexPath, reply: true)
                case false:
                    let comment = indexPath.section
                    self.sendDeleteLikeRequest(likeid: self.comments[comment].likeId, commentId: self.comments[comment].id, cell: cell, indexPath: indexPath, reply: false)
                }
                
            }
        } else {
            switch reply {
            case true:
                comments[indexPath.row - 1].liked = true
            case false:
                comments[indexPath.section].liked = true
            }
            self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: alreadyLiked)
            let subtot = cell.likes + 1
            switch reply {
            case true:
                comments[indexPath.row - 1].likes = subtot
            case false:
                comments[indexPath.section].likes = subtot
            }
            
            self.changeLikeCount(likeNumber: likes, indexPath: indexPath, reply: reply)
            throttler.throttle {
                switch reply {
                case true:
                    self.sendLikeRequest(commentId: self.comments[indexPath.row - 1].id, cell: cell, indexPath: indexPath, reply: true)
                case false:
                    self.sendLikeRequest(commentId: self.comments[indexPath.section].id, cell: cell, indexPath: indexPath, reply: false)
                }
                
                
            }
        }
        
    }
    
    // MARK: Update Heart Icon
    func changeHeartIcon(indexPath: IndexPath, reply: Bool, alreadyLiked: Bool) {
        switch alreadyLiked {
        case true:
            switch reply {
            case true:
                let cell = tableView.cellForRow(at: indexPath) as? ReplyTableViewCell
                DispatchQueue.main.async {
                    cell?.likeButton.image = UIImage(systemName: "heart.fill")
                    cell?.likeButton.tintColor = UIColor.systemRed
                }
            case false:
                let cell = tableView.cellForRow(at: indexPath) as? CommentCell
                DispatchQueue.main.async {
                    cell?.likeButton.image = UIImage(systemName: "heart.fill")
                    cell?.likeButton.tintColor = UIColor.systemRed
                }
            }
        case false:
            switch reply {
            case true:
                let cell = tableView.cellForRow(at: indexPath) as? ReplyTableViewCell
                DispatchQueue.main.async {
                    cell?.likeButton.image = UIImage(systemName: "heart")
                    cell?.likeButton.tintColor = UIColor.lightGray
                }
            case false:
                let cell = tableView.cellForRow(at: indexPath) as? CommentCell
                DispatchQueue.main.async {
                    cell?.likeButton.image = UIImage(systemName: "heart")
                    cell?.likeButton.tintColor = UIColor.lightGray
                }
            }
        }
    }
    
    func readMoreButtonTapped(commentId: Int, indexPath: IndexPath) {
        if indexPath.row == 0 {
            switch comments[indexPath.section].opened {
            case true:
                comments[indexPath.section].opened = false
                let sections = IndexSet.init(integer: indexPath.section)
                tableView.reloadSections(sections, with: .automatic)
            case false:
                comments[indexPath.section].opened = true
                let sections = IndexSet.init(integer: indexPath.section)
                tableView.reloadSections(sections, with: .automatic)
            case .none:
                comments[indexPath.section].opened = true
                let sections = IndexSet.init(integer: indexPath.section)
                tableView.reloadSections(sections, with: .automatic)
            case .some(_):
                comments[indexPath.section].opened = false
                let sections = IndexSet.init(integer: indexPath.section)
                tableView.reloadSections(sections, with: .automatic)
            }
        }
    }
    
    
}
extension CommentingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count
    }
    
    // MARK: Cell for row at
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataIndex = indexPath.row - 1
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell else { return UITableViewCell() }
            let comment = comments[indexPath.section]
            let usernameComment = comment.created_by
            cell.delegate = self
            cell.comment.text = comment.body // Add handling if comment is over a certain number of characters
            cell.indexPath = indexPath
            cell.commentUsername.text = usernameComment
            cell.likeNumber.text = String(comment.likes)
            switch comment.liked {
            case true:
                cell.likeButton.image = UIImage(systemName: "heart.fill")
                cell.likeButton.tintColor = UIColor.systemRed
            case false:
                cell.likeButton.image = UIImage(systemName: "heart")
                cell.likeButton.tintColor = UIColor.lightGray
                
            }
            AF.request("http://10.0.0.2:3000/api/v1/channels/\(usernameComment).json").responseJSON { response in
                       var JSON: [String: Any]?
                       do {
                           JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                           let imageUrl = JSON!["avatar_url"] as? String
                           let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                        guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else { return }
                           DispatchQueue.main.async {
                               Nuke.loadImage(with: railsUrl ?? imageURL, into: cell.commentAvatar)
                           }
                       } catch {
                           return
                       }
            }
            if comment.replies?.isEmpty == true {
                cell.readMoreButton.isHidden = true
            } else {
                if comment.replies?.count ?? 0 > 1 {
                    cell.readMoreButton.setTitle("Read \(comment.replies?.count ?? 0) Replies", for: .normal)
                } else {
                    cell.readMoreButton.setTitle("Read \(comment.replies?.count ?? 0) Reply", for: .normal)
                }
                
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyTableViewCell") as? ReplyTableViewCell else { return UITableViewCell() }
            guard let reply = comments[indexPath.section].replies?[dataIndex] else { return cell }
            cell.delegate = self
            cell.comment.text = reply.body
            cell.parentId = reply.parent_id
            cell.commentId = reply.id
            cell.indexPath = indexPath
            let username = reply.created_by
            cell.username.text = username
            cell.likeNumber.text = String(reply.likes)
            switch comments[indexPath.row].liked {
            case true:
                cell.likeButton.image = UIImage(systemName: "heart.fill")
                cell.likeButton.tintColor = UIColor.systemRed
            case false:
                cell.likeButton.image = UIImage(systemName: "heart")
                cell.likeButton.tintColor = UIColor.lightGray
            }
            AF.request("http://10.0.0.2:3000/api/v1/channels/\(username).json").responseJSON { response in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let imageUrl = JSON!["avatar_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {return}
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl ?? imageURL, into: cell.avatar)
                    }
                } catch {
                    return
                }
            }
            return cell
        }
        
        
    }
    
    // MARK: Number Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if comments[section].opened == true {
            return (comments[section].replies?.count ?? 1) + 1
        } else {
            return 1
        }
    }
    
    // MARK: Height For Row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if comments[indexPath.section].replies?.isEmpty != true && indexPath.row != 0 {
            return 60
        } else if comments[indexPath.section].replies?.isEmpty != true {
            return 85
        } else {
            return 60
        }
    }
    
    // MARK: Selected Row At
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}