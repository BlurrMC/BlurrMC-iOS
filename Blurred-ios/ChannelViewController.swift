//
//  ChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Nuke
import SwiftUI

class ChannelViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate { // Look at youself. Look at what you have done.
    
    

    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let lineView = UIView(frame: CGRect(x: 0, y: 220, width: self.view.frame.size.width, height: 1))
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
        
        // Setup the view so you can integerate it right away with the channel api.
    }
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            print("Image Tapped")
            pickAvatar()

        }
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
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json")
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
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            avatarImage.image = image
            postRequest()
        } else {
            self.showUnkownError()
        }
        self.dismiss(animated: true, completion: nil)
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
        // create the alert
        
    }
    func postRequest(){
    // the image in UIImage type
        guard let image = avatarImage else { return  }

    let filename = "avatar.png"

    // generate boundary string using a unique per-app string
    let boundary = UUID().uuidString

    let fieldName = "reqtype"
    let fieldValue = "fileupload"

    let fieldName2 = "userhash"
    let fieldValue2 = "caa3dce4fcb36cfdf9258ad9c"

    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)

    // Set the URLRequest to POST and to the specified URL
    var urlRequest = URLRequest(url: URL(string: "http://10.0.0.2:3000")!)
    urlRequest.httpMethod = "POST"

    // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
    // And the boundary is also set here
    urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var data = Data()

    // Add the reqtype field and its value to the raw http request data
    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n\r\n".data(using: .utf8)!)
    data.append("\(fieldValue)".data(using: .utf8)!)

    // Add the userhash field and its value to the raw http reqyest data
    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"\(fieldName2)\"\r\n\r\n".data(using: .utf8)!)
    data.append("\(fieldValue2)".data(using: .utf8)!)

    // Add the image data to the raw http request data
    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
    data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
    data.append(image.image!.pngData()!)

    // End the raw http request data, note that there is 2 extra dash ("-") at the end, this is to indicate the end of the data
    data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    // Send a POST request to the URL, with the data we created earlier
    session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
        
        if(error != nil){
            print("\(error!.localizedDescription)")
            self.showErrorContactingServer()
        }
        
        guard let responseData = responseData else {
            print("no response data")
            return
        }
        
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("uploaded to: \(responseString)")
        }
    }).resume()
    }
    // This checks in with the api and makes sure the token is right and then with the id it goes to the id's (or current user's) channel.

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
