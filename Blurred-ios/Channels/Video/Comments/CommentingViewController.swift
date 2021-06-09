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
import TTGSnackbar

class CommentingViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Variables
    private var comments = [Comment]()
    var videoId = String()
    var isReplyKeyboardUp = Bool()
    var replyParentId = String()
    var replyIndex = IndexPath()
    var isItEditing: Bool = false
    var isEditingAReply = Bool()
    var originalUneditedText = String()
    var name = String()
    var username = String()
    
    var cellIsReported = Bool()
    var cellName = String()
    var cellUsername = String()
    var cellAvatarUrl = String()
    var fromCell = Bool()
    
    
    // MARK: Outlets
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var replyField: UITextField!
    
    
    // MARK: Valet
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    
    // MARK: Get the user's avatar
    func getAvatar() {
        if let avatarUrl: String  = try? myValet.string(forKey: "avatar url") {
            guard let url = URL(string: avatarUrl) else { return }
            DispatchQueue.main.async {
                Nuke.loadImage(with: url, into: self.userAvatar)
            }
        }
        guard let userId: String = try? myValet.string(forKey: "Id") else { return }
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(userId).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                guard let imageUrl = JSON!["avatar_url"] as? String else { return }
                guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(imageUrl)") else { return }
                DispatchQueue.main.async {
                    Nuke.loadImage(with: railsUrl, into: self.userAvatar)
                    try? self.myValet.setString(railsUrl.absoluteString, forKey: "avatar url for \(userId)")
                }
                guard let name = JSON!["name"] as? String else { return }
                guard let username = JSON!["username"] as? String else { return }
                self.username = username
                self.name = name
            } catch {
                return
            }
        }
    }
    
    
    // MARK: Text Field Should Return (Send Button)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == commentField {
            submitComment(reply: false)
            downloadJson(fromReply: false)
        } else {
            switch isItEditing {
            case true:
                if self.replyField.text != nil {
                    submitEditedComment(indexPath: replyIndex, reply: isEditingAReply)
                } else {
                    switch isEditingAReply {
                    case true:
                        deleteComment(indexPath: replyIndex, commentId: self.comments[replyIndex.section].replies?[replyIndex.row - 1].id, reply: true)
                    case false:
                        deleteComment(indexPath: replyIndex, commentId: self.comments[replyIndex.section].id, reply: true)
                    }
                    
                }
                
            case false:
                submitComment(reply: true)
            }
        }
        return true
    }
    
    
    // MARK: Received Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Reply Keyboard
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIApplication.keyboardWillShowNotification {
            replyField.frame.origin.y = keyboardRect.minY - replyField.frame.height - 50 // Align this better
        } else {
            replyField.frame.origin.y = 0
            replyField.isHidden = true
            
        }
    }
    
    deinit {
        // Remove listeners for the keyboard
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Submit the user's comment
    func submitComment(reply: Bool) {
        // Add edit function so you can edit it if is your (and remove it) and if it isn't yours then you can report the comment.
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let token: String? = try? tokenValet.string(forKey: "Token")
        let myUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        if replyField?.text?.isEmpty != true || commentField?.text?.isEmpty != true {
            let comment = commentField.text
            let replyBody = replyField.text
            do {
                switch reply {
                case true:
                    let patchString = [
                        "comment": [
                            "body": replyBody as Any,
                            "parent_id": replyParentId
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
                    DispatchQueue.main.async {
                        self.replyField.text = nil
                        self.replyField.isHidden = true
                    }
                case false:
                    let patchString = ["comment": ["body": comment]]
                    request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
                }
                
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
                        } else {
                            DispatchQueue.main.async {
                                self.commentField.text = ""
                            }
                            self.downloadJson(fromReply: reply)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.replyField.text = nil
                        }
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        print(error ?? "No error")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.replyField.text = nil
                    }
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    let snackbar = TTGSnackbar(message: "Error contacting server, try again later.", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                    print(error)
                }
            }
            task.resume()
        } else {
            replyField.text = nil
            self.showMessage(title: "Alert", message: "Your comment is empty. Just type something!", alertActionTitle: "OK")
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
        let id: String
        let reply: Bool
        let time_since_creation: String
        var body: String
        var liked: Bool
        let parent_id: String?
        var replies: [Comment]?
        var opened: Bool? = false
        var likeId: String?
        var reported: Bool
        var comment_is_editable: Bool
        var edited: Bool
        init(created_by: String, likes: Int, body: String, id: String, reply: Bool, time_since_creation: String, liked: Bool, parent_id: String, replies: [Comment]?, likeId: String, reported: Bool, comment_is_editable: Bool, edited: Bool) {
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
                self.parent_id = nil
            }
            self.replies = replies
            self.reported = reported
            self.likeId = likeId
            self.comment_is_editable = comment_is_editable
            self.edited = edited
        }
    }
    
    // MARK: Download the comments
    func downloadJson(fromReply: Bool) { // Still not done we need to add the user's butt image
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/", method: .get, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: coi329fj482")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedComments = try decoder.decode(Comments.self, from: data)
                self.comments = downloadedComments.comments
                if fromReply == true {
                    guard let _ = self.comments[safe: self.replyIndex.section] else { return }
                    self.comments[self.replyIndex.section].opened = true
                }
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
        downloadJson(fromReply: false)
        // Listen for keyboard events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        replyField.backgroundColor = UIColor.darkGray
        self.userAvatar.contentScaleFactor = 1.5
        let contentModes = ImageLoadingOptions.ContentModes(
            success: .scaleAspectFill,
            failure: .scaleAspectFill,
            placeholder: .scaleAspectFill)
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = UIImage(named: "load-image")
        ImageLoadingOptions.shared.failureImage = UIImage(named: "load-image")
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.25)
        DataLoader.sharedUrlCache.diskCapacity = 0
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.avatarTap(sender:)))
        self.userAvatar.addGestureRecognizer(avatarTap)
        
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }
    
    // MARK: Segue Data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let vc = segue.destination as? OtherChannelViewController {
            if segue.identifier == "showCommentChannel" {
                switch fromCell {
                case true:
                    vc.chanelVar = self.cellUsername
                    vc.segueName = self.cellName
                    vc.channelUsername = self.cellUsername
                    vc.segueUsername = self.cellUsername
                    vc.isReported = self.cellIsReported
                    vc.avatarUrl = self.cellAvatarUrl
                case false:
                    vc.chanelVar = self.username
                    if let avatarUrl: String = try? myValet.string(forKey: "avatar url") {
                        vc.avatarUrl = avatarUrl
                    }
                    vc.channelUsername = username
                    vc.segueName = name
                }
            }
        }
    }
    
    // MARK: Avatar Tapped
    @objc func avatarTap(sender:UITapGestureRecognizer) {
        self.fromCell = false
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showCommentChannel", sender: self)
        }
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        getAvatar()
    }
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
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
    
    
    // MARK: Avatar Tapped (Go to channel)
    func cellAvatarTapped(commentId: String, indexPath: IndexPath, reply: Bool, name: String, isReported: Bool, avatarUrl: String) {
        switch reply {
        case true:
            guard let username = self.comments[indexPath.section].replies?[indexPath.row - 1].created_by else { return }
            self.fromCell = true
            self.cellUsername = username
            self.cellName = name
            self.cellAvatarUrl = avatarUrl
            self.cellIsReported = isReported
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showCommentChannel", sender: self)
            }
        case false:
            let username = self.comments[indexPath.section].created_by
            self.fromCell = true
            self.cellUsername = username
            self.cellName = name
            self.cellAvatarUrl = avatarUrl
            self.cellIsReported = isReported
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showCommentChannel", sender: self)
            }
        }
    }
    
    
    // MARK: Submit an edited comment
    func submitEditedComment(indexPath: IndexPath, reply: Bool) {
        switch reply {
        case true:
            self.comments[indexPath.section].replies?[indexPath.row - 1].body = self.replyField.text ?? originalUneditedText
        case false:
            self.comments[indexPath.section].body = self.replyField.text ?? originalUneditedText
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        switch reply {
        case true:
            guard let reply = self.comments[indexPath.section].replies?[indexPath.row - 1] else { return }
            let params = [
                "body": reply.body,
                "parent_id": reply.parent_id!
            ] as [String : Any]
            let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/\(reply.id)")
            AF.request(URL.init(string: url)!, method: .patch, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let status = JSON!["status"] as? String
                    if status != "Comment updated." {
                        print("error code: asc9r822ma919d382hf")
                    }
                } catch {
                    print(error)
                    print("error code: aisajc238998232")
                    return
                }
            }
        case false:
            let comment = self.comments[indexPath.section]
            let params = [
                "body": comment.body
            ] as [String : Any]
            let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/\(comment.id)")
            AF.request(URL.init(string: url)!, method: .patch, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let status = JSON!["status"] as? String
                    if status != "Comment updated." {
                        print("error code: 9fj29ej1n2d8ad")
                    }
                } catch {
                    print(error)
                    print("error code: kg934nbxbbbcxbxhae823euji")
                    return
                }
            }
        }
        
    }
    
    
    
    // MARK: Edit a comment
    func editComment(indexPath: IndexPath, reply: Bool) {
        self.replyIndex = indexPath
        self.replyField.isHidden = false
        self.isItEditing = true
        switch reply {
        case true:
            guard let reply = self.comments[indexPath.section].replies?[indexPath.row - 1] else { return }
            self.originalUneditedText = reply.body
            self.replyField.text = reply.body
        case false:
            let comment = self.comments[indexPath.section]
            self.originalUneditedText = comment.body
            self.replyField.text = comment.body
        }
        self.replyField.becomeFirstResponder()
    }
    
    
    // MARK: Delete a comment
    func deleteComment(indexPath: IndexPath, commentId: String?, reply: Bool) {
        switch reply {
        case true:
            self.comments.remove(at: indexPath.row - 1)
        case false:
            self.comments.remove(at: indexPath.section)
        }
        DispatchQueue.main.async {
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/\(commentId)")
        AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Comment Destroyed!" {
                    let snackbar = TTGSnackbar(message: "Message could not be deleted!", duration: .middle)
                    DispatchQueue.main.async {
                        snackbar.show()
                    }
                }
            } catch {
                print(error)
                print("error code: aog92mxz932")
                return
            }
        }
    }
    
    
    // MARK: Report a comment
    func reportComment(commentId: String?) {
        guard let commentId = commentId else { return }
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        let params = [
            "video_id": videoId,
            "comment_id": commentId
        ] as [String: Any]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/reports")
        AF.request(URL.init(string: url)!, method: .post, parameters: params as Parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let status = JSON!["status"] as? String
                if status != "Reported" {
                    print("error code: 1vnt92mt9a2")
                }
            } catch {
                print(error)
                print("error code: 10y19692420")
                return
            }
        }
    }
    
    func moreButtonTapped(commentId: String, indexPath: IndexPath, reply: Bool) {
        // Change the actionSheet to a custom made stack view to look better
        let alert = UIAlertController(title: "More", message: "More Options", preferredStyle: UIAlertController.Style.actionSheet)

        switch reply {
        case true:
            let reply = self.comments[indexPath.section].replies?[indexPath.row - 1]
            if reply?.reported != true {
                alert.addAction(UIAlertAction(title: "Report", style: UIAlertAction.Style.default, handler: {_ in
                    self.comments[indexPath.section].replies?[indexPath.row - 1].reported = true
                    self.reportComment(commentId: commentId)
                }))
            }
            if reply?.comment_is_editable == true {
                alert.addAction(UIAlertAction(title: "Edit", style: UIAlertAction.Style.default, handler: {_ in
                    self.editComment(indexPath: indexPath, reply: true)
                }))
                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive, handler: {_ in
                    self.deleteComment(indexPath: indexPath, commentId: commentId, reply: true)
                }))
            }
        case false:
            let comment = self.comments[indexPath.section]
            if comment.reported != true {
                alert.addAction(UIAlertAction(title: "Report", style: UIAlertAction.Style.default, handler: {_ in
                    self.comments[indexPath.section].reported = true
                    self.reportComment(commentId: commentId)
                }))
            }
            if comment.comment_is_editable == true {
                alert.addAction(UIAlertAction(title: "Edit", style: UIAlertAction.Style.default, handler: {_ in
                    self.editComment(indexPath: indexPath, reply: false)
                }))
                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive, handler: {_ in
                    self.deleteComment(indexPath: indexPath, commentId: commentId, reply: false)
                }))
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func likeButtonTapped(commentId: String, indexPath: IndexPath, reply: Bool) {
        let commentIndex = indexPath.section
        switch reply {
        case true:
            guard let reply = comments[commentIndex].replies?[indexPath.row - 1] else { return }
            like(alreadyLiked: reply.liked, cell: reply, likes: reply.likes, indexPath: indexPath, reply: true)
        case false:
            let comment = comments[commentIndex]
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
            default:
                DispatchQueue.main.async {
                    cell?.likeNumber.text = "\(likeNumber)"
                }
            }
        }
        
    }
    
    // MARK: Unlike Video
    func sendDeleteLikeRequest(likeid: String?, commentId: String, cell: Comment, indexPath: IndexPath, reply: Bool) {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let throttler = Throttler(minimumDelay: 5)
        if likeid != nil, let likeid = likeid {
            let url = "https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/\(commentId)/commentlikes/\(likeid)"
            throttler.throttle( {
                AF.request(URL.init(string: url)!, method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                    var JSON: [String: Any]?
                    guard let data = response.data else { return }
                    let commentIndex = indexPath.section
                    let replyIndex = indexPath.row - 1
                    do {
                        JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        let status = JSON!["status"] as? String
                        if status == "Video has been unliked." {
                            switch reply {
                            case true:
                                guard let _ = self.comments[safe: commentIndex]?.replies?[safe: replyIndex] else { return }
                                self.comments[commentIndex].replies?[replyIndex].liked = false
                                self.comments[commentIndex].replies?[replyIndex].likeId = nil
                            case false:
                                self.comments[commentIndex].liked = false
                                self.comments[commentIndex].likeId = nil
                            }
                            
                        }
                    } catch {
                        switch reply {
                        case true:
                            guard let _ = self.comments[safe: commentIndex]?.replies?[safe: replyIndex] else { return }
                            self.comments[commentIndex].replies?[replyIndex].liked = false
                            self.comments[commentIndex].replies?[replyIndex].likeId = nil
                        case false:
                            guard let _ = self.comments[safe: commentIndex] else { return }
                            self.comments[commentIndex].liked = false
                            self.comments[commentIndex].likeId = nil
                        }
                        print("This typically isn't supposed to happen, but might. Ignore this unless a serious issue. error code: 0fnboglap139gnza")
                        return
                    }
                }
            }, uniqueId: indexPath.row)
            
        }
        
    }
    
    
    // MARK: Like the comment
    func sendLikeRequest(commentId: String, cell: Comment, indexPath: IndexPath, reply: Bool) {
        let token: String? = try? tokenValet.string(forKey: "Token")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("https://www.bartenderdogseatmuffins.xyz/api/v1/videos/\(videoId)/comments/\(commentId)/commentlikes")
        let throttler = Throttler(minimumDelay: 5)
        throttler.throttle( {
            AF.request(URL.init(string: url)!, method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let status = JSON!["status"] as? String
                    let commentIndex = indexPath.section
                    let replyIndex = indexPath.row - 1
                    switch status {
                    case "You have already liked it!":
                        let likeid = JSON!["likeid"] as? String
                        self.sendDeleteLikeRequest(likeid: likeid, commentId: commentId, cell: cell, indexPath: indexPath, reply: reply)
                    case "Video has been liked":
                        let likeid = JSON!["likeid"] as? String
                        switch reply {
                        case true:
                            guard let _ = self.comments[safe: commentIndex]?.replies?[safe: replyIndex] else { return }
                            self.comments[commentIndex].replies?[replyIndex].liked = true
                            self.comments[commentIndex].replies?[replyIndex].likeId = likeid
                        case false:
                            guard let _ = self.comments[safe: commentIndex] else { return }
                            self.comments[commentIndex].liked = true
                            self.comments[commentIndex].likeId = likeid
                        }
                        self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: true)
                    case "Video has been unliked.":
                        switch reply {
                        case true:
                            guard let _ = self.comments[safe: commentIndex]?.replies?[safe: replyIndex] else { return }
                            self.comments[commentIndex].replies?[replyIndex].liked = false
                            self.comments[commentIndex].replies?[replyIndex].likeId = nil
                        case false:
                            guard let _ = self.comments[safe: commentIndex] else { return }
                            self.comments[commentIndex].replies?[replyIndex].liked = false
                            self.comments[commentIndex].replies?[replyIndex].likeId = nil
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

        }, uniqueId: indexPath.row)
    }
    
    
    // MARK: Like Tapped (For Delegate)
    func like(alreadyLiked: Bool, cell: Comment, likes: Int, indexPath: IndexPath, reply: Bool) {
        let replyIndex = indexPath.row - 1
        let commentIndex = indexPath.section
        if alreadyLiked == true {
            switch reply {
            case true:
                comments[commentIndex].replies?[replyIndex].liked = false
            case false:
                comments[commentIndex].liked = false
            }
            
            self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: false)
            if cell.likes != 0 {
                let subtot = cell.likes - 1
                switch reply {
                case true:
                    comments[commentIndex].replies?[replyIndex].likes = subtot
                case false:
                    comments[commentIndex].likes = subtot
                }
                self.changeLikeCount(likeNumber: subtot, indexPath: indexPath, reply: reply)
            }
            switch reply {
            case true:
                let reply = indexPath.row - 1
                self.sendDeleteLikeRequest(likeid: self.comments[reply].likeId, commentId: self.comments[reply].id, cell: cell, indexPath: indexPath, reply: true)
            case false:
                let comment = indexPath.section
                self.sendDeleteLikeRequest(likeid: self.comments[comment].likeId, commentId: self.comments[comment].id, cell: cell, indexPath: indexPath, reply: false)
            }
                
        } else {
            switch reply {
            case true:
                comments[commentIndex].replies?[replyIndex].liked = true
            case false:
                comments[commentIndex].liked = true
            }
            self.changeHeartIcon(indexPath: indexPath, reply: reply, alreadyLiked: true)
            let subtot = cell.likes + 1
            switch reply {
            case true:
                comments[commentIndex].replies?[replyIndex].likes = subtot
            case false:
                comments[commentIndex].likes = subtot
            }
            self.changeLikeCount(likeNumber: subtot, indexPath: indexPath, reply: reply)
            switch reply {
            case true:
                self.sendLikeRequest(commentId: self.comments[indexPath.row - 1].id, cell: cell, indexPath: indexPath, reply: true)
            case false:
                self.sendLikeRequest(commentId: self.comments[indexPath.section].id, cell: cell, indexPath: indexPath, reply: false)
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
    
    
    // MARK: Read more button tap
    func readMoreButtonTapped(commentId: String, indexPath: IndexPath) {
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
    
    // MARK: Number Of Sections
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
            if comment.edited == true {
                cell.comment.text = comment.body + " (edited)"
            }
            cell.indexPath = indexPath
            cell.commentUsername.text = usernameComment
            let likeNumber = comment.likes
            switch likeNumber {
            case _ where likeNumber > 1000 && likeNumber < 100000:
                cell.likeNumber.text = "\(likeNumber/1000).\((likeNumber/100)%10)k"
            case _ where likeNumber > 100000 && likeNumber < 1000000:
                cell.likeNumber.text = "\(likeNumber/1000)k"
            case _ where likeNumber > 1000000 && likeNumber < 100000000:
                cell.likeNumber.text = "\(likeNumber/1000000).\((likeNumber/1000)%10)M"
            case _ where likeNumber > 100000000:
                cell.likeNumber.text = "\(likeNumber/1000000)M"
            default:
                cell.likeNumber.text = "\(likeNumber)"
            }
            switch comment.liked {
            case true:
                cell.likeButton.image = UIImage(systemName: "heart.fill")
                cell.likeButton.tintColor = UIColor.systemRed
            case false:
                cell.likeButton.image = UIImage(systemName: "heart")
                cell.likeButton.tintColor = UIColor.lightGray
                
            }
            AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(usernameComment).json").responseJSON { response in
                guard let data = response.data else { return }
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let imageUrl = JSON!["avatar_url"] as? String
                    guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.commentAvatar)
                    }
                    guard let name = JSON!["name"] as? String else { return }
                    guard let isReported = JSON!["reported"] as? Bool else { return }
                    cell.commentName = name
                    cell.reported = isReported
                    cell.avatarUrl = railsUrl.absoluteString
                } catch {
                    return
                }
            }
            guard let repliesCount = comment.replies?.count else {
                cell.readMoreButton.isHidden = true
                return cell // This should be the end if the comment has no replies
            }
            if repliesCount > 1 {
                cell.readMoreButton.setTitle("Read \(comment.replies?.count ?? 0) Replies", for: .normal)
            } else if repliesCount == 1 {
                cell.readMoreButton.setTitle("Read \(comment.replies?.count ?? 0) Reply", for: .normal)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyTableViewCell") as? ReplyTableViewCell else { return UITableViewCell() }
            guard let reply = comments[indexPath.section].replies?[dataIndex] else { return cell }
            cell.delegate = self
            cell.comment.text = reply.body
            if reply.edited == true {
                cell.comment.text = reply.body + " (edited)"
            }
            guard let parentId = reply.parent_id else { return cell }
            cell.parentId = parentId
            cell.commentId = reply.id
            cell.indexPath = indexPath
            let username = reply.created_by
            cell.username.text = username
            let likeNumber = reply.likes
            switch likeNumber {
            case _ where likeNumber > 1000 && likeNumber < 100000:
                cell.likeNumber.text = "\(likeNumber/1000).\((likeNumber/100)%10)k"
            case _ where likeNumber > 100000 && likeNumber < 1000000:
                cell.likeNumber.text = "\(likeNumber/1000)k"
            case _ where likeNumber > 1000000 && likeNumber < 100000000:
                cell.likeNumber.text = "\(likeNumber/1000000).\((likeNumber/1000)%10)M"
            case _ where likeNumber > 100000000:
                cell.likeNumber.text = "\(likeNumber/1000000)M"
            default:
                cell.likeNumber.text = "\(likeNumber)"
            }
            switch reply.liked {
            case true:
                cell.likeButton.image = UIImage(systemName: "heart.fill")
                cell.likeButton.tintColor = UIColor.systemRed
            case false:
                cell.likeButton.image = UIImage(systemName: "heart")
                cell.likeButton.tintColor = UIColor.lightGray
            }
            
            AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(username).json").responseJSON { response in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let imageUrl = JSON!["avatar_url"] as? String
                    guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(imageUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.avatar)
                    }
                    guard let name = JSON!["name"] as? String else { return }
                    guard let isReported = JSON!["reported"] as? Bool else { return }
                    cell.name = name
                    cell.isReported = isReported
                    cell.avatarUrl = railsUrl.absoluteString
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
        if comments[indexPath.section].replies?.isEmpty == false && indexPath.row != 0 {
            return 60
        } else if comments[indexPath.section].replies?.isEmpty == false {
            return 85
        } else {
            return 60
        }
    }
    
    // MARK: Selected Row At
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dataIndex = indexPath.row - 1
        if indexPath.row == 0 {
            guard let parentId = self.comments[indexPath.section].parent_id else { return }
            self.replyParentId = parentId
        } else {
            self.replyParentId = self.comments[indexPath.section].replies?[dataIndex].parent_id ?? self.comments[indexPath.section].id
        }
        isItEditing = false
        self.replyIndex = indexPath
        self.replyField.isHidden = false
        self.replyField.becomeFirstResponder()
    }
    
    
}
extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
