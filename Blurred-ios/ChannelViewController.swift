//
//  ChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke
import SwiftUI
import Alamofire

class ChannelViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate { // Look at youself. Look at what you have done.
    
    

    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    var timer = Timer()
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    @IBAction func settingsButtonTap(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let lineView = UIView(frame: CGRect(x: 0, y: 245, width: self.view.frame.size.width, height: 1))
        lineView.backgroundColor = UIColor.black
        self.view.addSubview(lineView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.imageTapped(gesture:)))
        avatarImage.isUserInteractionEnabled = true
        avatarImage.addGestureRecognizer(tapGesture)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tappFunction))
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        // Setup the view so you can integerate it right away with the channel api.
    }
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            print("Image Tapped")
            pickAvatar()
        }
    }
    @objc func timerAction() {
        if myValet.string(forKey: "Id") == nil {
            self.timer.invalidate()
        } else {
            loadMemberChannel()
        }
        print("timer activated")
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        print("tap working")
        goToFollowersList()
    }
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    func goToFollowersList() {
        let followersListPage = self.storyboard?.instantiateViewController(identifier: "FollowerListViewController") as! FollowerListViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = followersListPage
        self.present(followersListPage, animated:true, completion:nil)
    }
    func goToFollowingList() {
        let followeringListPage = self.storyboard?.instantiateViewController(identifier: "FollowListViewController") as! FollowListViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = followeringListPage
        self.present(followeringListPage, animated:true, completion:nil)
    }
    func loadMemberChannel() {
        let userId: String?  = myValet.string(forKey: "Id")
        let Id = Int(userId!)
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.showErrorContactingServer()
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let username: String? = parseJSON["username"] as? String
                    let name: String? = parseJSON["name"] as? String
                    let imageUrl: String? = parseJSON["image_url"] as? String
                    let followerCount: Int? = parseJSON["followers_count"] as? Int
                    let followingCount: Int? = parseJSON["following_count"] as? Int
                    let bio: String? = parseJSON["bio"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
                        if bio?.isEmpty != true {
                            self.bioLabel.text = bio!
                        } else {
                            self.bioLabel.text = String("")
                        }
                        if username?.isEmpty != true && name?.isEmpty != true {
                            self.usernameLabel.text = username!
                            self.nameLabel.text = name!
                        } else {
                            self.showNoResponseFromServer()
                        }
                        print(followerCount ?? "none")
                        if followerCount != 0 {
                            self.followersLabel.text = "\(followerCount ?? 0)"
                        } else {
                            self.followersLabel.text = "0"
                        }
                        if followingCount != 0 {
                            self.followingLabel.text = "\(followingCount ?? 0)"
                        } else {
                            self.followingLabel.text = "0"
                        }
                        Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
                        }
                } else {
                    self.showErrorContactingServer()
                    print(error ?? "No error")
                }
            } catch {
                    self.showNoResponseFromServer()
                    print(error)
                }
        }
        task.resume()
    } // I will set this up later
    
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    func upload() {
        let token: String?  = self.tokenValet.string(forKey: "Token")
        let userId: String?  = self.myValet.string(forKey: "Id")
        let Id = Int(userId!)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/registrations/\(Id!)")
        let image = avatarImage.image///haha im small
        guard let imgcompressed = image?.jpegData(compressionQuality: 0.5) else { return }
        // Insert AF upload patch request here.
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imgcompressed, withName: "avatar" , fileName: "\(Id!)-avatar.png", mimeType: "image/png")
        },
            to: url, method: .patch , headers: headers)
            .response { resp in
                print(resp)


        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            avatarImage.image = image
            upload()
        } else {
            self.showUnkownError()
        }
        self.dismiss(animated: true, completion: nil)
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showUnkownError() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "We don't know what happend wrong here! Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Fine", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func pickAvatar() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Avatar", message: "Change your avatar.", preferredStyle: UIAlertController.Style.actionSheet)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "Pick from gallery", style: UIAlertAction.Style.default, handler: { action in
                print("Pick from gallery")
                self.importImage()
            }))
            alert.addAction(UIAlertAction(title: "Take photo", style: UIAlertAction.Style.default, handler: { action in
                print("Take photo")
                self.takePicture()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
}
