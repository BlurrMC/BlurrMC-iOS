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

class CommentingViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
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
    
    
    // MARK: Number Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }
    
    
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
    
    
    // MARK: Cell for row at
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell else { return UITableViewCell() }
        let usernameComment = comments[indexPath.row].created_by
        cell.delegate = self
        cell.comment.text = comments[indexPath.row].body // Add handling if comment is over a certain number of characters
        cell.indexPath = indexPath
        cell.commentUsername.text = usernameComment
        cell.likeNumber.text = String(comments[indexPath.row].likes)
        switch comments[indexPath.row].liked {
        case true:
            cell.likeButton.image = UIImage(systemName: "heart.fill")
        case false:
            cell.likeButton.image = UIImage(systemName: "heart")
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
        return cell
    }
    
    
    // MARK: Comments Gotten From JSON
    class Comments: Codable {
        let comments: [Comment]
        init(comments: [Comment]) {
            self.comments = comments
        }
    }
    class Comment: Codable {
        let created_by: String
        let likes: Int
        let id: Int
        let reply: Bool
        let time_since_creation: String
        let body: String
        let liked: Bool
        // Add replies
        init(created_by: String, likes: Int, body: String, id: Int, reply: Bool, time_since_creation: String, liked: Bool) {
            self.id = id
            self.reply = reply
            self.time_since_creation = time_since_creation
            self.created_by = created_by
            self.likes = likes
            self.body = body
            self.liked = liked
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
    func likeButtonTapped(commentId: Int, indexPath: IndexPath) {
        
    }
    
    
}
