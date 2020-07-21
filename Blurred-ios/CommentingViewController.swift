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
    private var comments = [Comment]()
    var videoId = Int()
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == commentField {
            textField.resignFirstResponder()
            submitComment()
            downloadJson()
        }
        return true
    }
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
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/comments/\(videoId).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        if commentField?.text?.isEmpty != true {
            let comment = commentField.text
            let patchString = ["comment": comment!] as [String: String]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: patchString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                return
            }
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.showNoResponseFromServer()
                    print("error=\(String(describing: error))")
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let parseJSON = json {
                        let returnCode = parseJSON["status"] as? String
                        if returnCode != String("Commented") {
                            self.showErrorContactingServer()
                        }
                    } else {
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        self.showNoResponseFromServer()
                        print(error ?? "No error")
                    }
                } catch {
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                    self.showErrorContactingServer()
                    print(error)
                }
            }
            task.resume()
        } else {
            self.showEmptyComment()
        }
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell else { return UITableViewCell() }
        let usernameComment = comments[indexPath.row].username
        cell.commentUsername.text = usernameComment
        cell.comment.text = comments[indexPath.row].comment // Add handling if comment is over a certain number of characters
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
    
    class Comments: Codable {
        let comments: [Comment]
        init(comments: [Comment]) {
            self.comments = comments
        }
    }
    // MARK: Download the comments
    func downloadJson() { // Still not done we need to add the user's butt image
        let url = URL(string: "http://10.0.0.2:3000/api/v1/comments/\(videoId).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                self.showNoResponseFromServer()
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
                print(error)
            }
        }.resume()
    }
    class Comment: Codable {
        let username: String
        let likecount: Int
        let comment: String
        init(username: String, likecount: Int, comment: String) {
            self.username = username
            self.likecount = likecount
            self.comment = comment
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        commentField?.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getAvatar()
    }
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    func showNoResponseFromServer() {
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showErrorContactingServer() {
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showEmptyComment() {
        let alert = UIAlertController(title: "Error", message: "You have nothing in your comment!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}
