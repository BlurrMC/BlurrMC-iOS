//
//  OtherFollowListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke

class OtherFollowListViewController: UIViewController, UITableViewDataSource {
    var followingVar = String()
    private var followings = [Following]()
    var timer = Timer()
    @IBOutlet weak var nothingHere: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()
        tableView.tableFooterView = UIView()
        print("\(followingVar)")
        timer = Timer.scheduledTimer(timeInterval: 360.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)

        // Do any additional setup after loading the view.
    }
    @objc func timerAction() {
        if myValet.string(forKey: "Id") == nil {
            self.timer.invalidate()
        } else if followingVar == nil {
            self.timer.invalidate()
        } else if followingVar != nil && myValet.string(forKey: "Id") != nil {
            downloadJson()
            print("timer activated")
        }
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    func downloadJson() { // Still not done we need to add the user's butt image
        let Id = followingVar
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelsfollowing/\(Id).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
                print("uh oh")
                return
            }
            print("I got the data")
            do {
                let decoder = JSONDecoder()
                let downloadedFollowing = try decoder.decode(Followings.self, from: data)
                self.followings = downloadedFollowing.following
                print("a1")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("You have no followerings go die.")
            }
        }.resume()
    }
    class Followings: Codable {
        let following: [Following]
        init(following: [Following]) {
            self.following = following
        }
    }
    class Following: Codable {
        let username: String
        let name: String
        let id: Int
        init(username: String, name: String, id: Int) {
            self.username = username
            self.name = name
            self.id = id
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followings.count
    }
    func tableView(tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = OtherChannelViewController()
        destinationVC.performSegue(withIdentifier: "showChannel", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            let detailVC = segue.destination as! OtherChannelViewController
            detailVC.chanelVar = followings[selectedRow].username
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OtherFollowingCell") as? OtherFollowingCell else { return UITableViewCell() }
        cell.followingUsername.text = followings[indexPath.row].username // Hey stupid if you want to add more just add one more line of code here
        cell.followingName.text = followings[indexPath.row].name
        DispatchQueue.main.async {
            if cell.followingUsername.text == nil {
                self.nothingHere.text = String("Nothing Here")
            } else {
                self.nothingHere.text = String("")
            }
        }
        let Id: Int? = followings[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                DispatchQueue.main.async {
                    self.showErrorContactingServer()
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let imageUrl: String? = parseJSON["image_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.followingAvatar)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer()
                    }
                    print(error ?? "No error")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
                print(error)
                }
        }
        task.resume()
        return cell
    }
    func showErrorContactingServer() {
        self.timer.invalidate()

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func showNoResponseFromServer() {
        self.timer.invalidate()

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
