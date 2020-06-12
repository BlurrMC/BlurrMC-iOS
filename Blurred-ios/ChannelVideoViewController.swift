//
//  ChannelVideoViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Valet

class ChannelVideoViewController: UIViewController {
    @IBOutlet weak var backButtonOutlet: UIButton!
    // Add peak function to dispaly video when peaking.
    
    @IBOutlet weak var descriptionLabel: UILabel!
    var videoString = Int()
    var videoUrlString = String()
    func sendRequest() {
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/videos/\(videoString).json")
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
                    let videoUrl: String? = parseJSON["video_url"] as? String
                    let descriptionString: String? = parseJSON["description"] as? String
                    self.videoUrlString = videoUrl!
                    DispatchQueue.main.async {
                        self.descriptionLabel.text = descriptionString ?? ""
                        self.babaPlayer()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorContactingServer()
                    }
                    print(error ?? "")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoResponseFromServer()
                }
                print(error)
                }
        }
        task.resume()
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.timer.invalidate()
        isDismissed = true
        avPlayer.pause()
    }
    @IBOutlet weak var videoView: UIView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()
        sendRequest()
        self.videoView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelVideoViewController.tapFunction))
        backButtonOutlet.layer.zPosition = 1
        videoView.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    var doubleTap : Bool! = false
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        if (doubleTap) {
            doubleTap = false
            avPlayer.play()
        } else {
            avPlayer.pause()
            doubleTap = true
        }
    }
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    @objc func timerAction() {
        let token: String? = tokenValet.string(forKey: "Token")
        if token == nil {
            self.timer.invalidate()
        } else {
            isDismissed = true
            avPlayer.pause()
        }
    }
    var isDismissed: Bool = false
    fileprivate var playerObserver: Any?
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        avPlayer.pause()
        isDismissed = true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        sendRequest()
        isDismissed = false
    }
    fileprivate var player: AVPlayer? {
        didSet { player?.play() }
    }
    deinit {
        guard let observer = playerObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    func babaPlayer() {
        let videoUrl = URL(string: "http://10.0.0.2:3000\(videoUrlString)")!
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoUrl as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
        if isDismissed != true {
            let resetPlayer = {
                self.avPlayer.seek(to: CMTime.zero)
                self.avPlayer.play()
            }
            playerObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem, queue: nil) { notification in
                resetPlayer()
            }
        } else {
            avPlayer.pause()
        }
        avPlayer.play()
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
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
}
