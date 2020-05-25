//
//  VideoPlaybaackViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/18/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//
import AVFoundation
import UIKit
import Valet
import Alamofire

class VideoPlaybackViewController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var timer = Timer()
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        isDismissed = true
        avPlayer.pause()
    }
    
    @objc func timerAction() {
        let token: String? = tokenValet.string(forKey: "Token")
        if token == nil {
            self.timer.invalidate()
        } else {
            isDismissed = false
            avPlayer.pause()
        }
    }
    var isDismissed: Bool = false
    fileprivate var player: AVPlayer? {
        didSet { player?.play() }
    }
    deinit {
        guard let observer = playerObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    fileprivate var playerObserver: Any?
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    var videoURL: URL!
    override func viewDidLoad() {
        super.viewDidLoad()
        babaPlayer()
                // Do any additional setup after loading the view.
    }
    func viewWillAppear() {
        super.viewWillAppear(true)
        isDismissed = false
        babaPlayer()
    }
    func viewWillDisappear() {
        super.viewWillDisappear(true)
        isDismissed = true
    }
    func babaPlayer() {
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoURL as URL)
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
    @IBAction func doneButton(_ sender: Any) {
        startRequest()
    }
    func startRequest() {
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let userId: String? = myValet.string(forKey: "Id")
        let token: String? = tokenValet.string(forKey: "Token")
        let Id = Int(userId!)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(self.videoURL, withName: "video[clip]" , fileName: "clip.mp4", mimeType: "video/mp4")
                multipartFormData.append("\(Id!)".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName :"user[Id]")

        },
            to: "http://10.0.0.2:3000/api/v1/videouploads.json", method: .post, headers: headers)
            .response { resp in
                print(resp)


        }
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    // I want to die
    func showErrorContactingServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)z
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    //
    func showNoResponseFromServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
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
