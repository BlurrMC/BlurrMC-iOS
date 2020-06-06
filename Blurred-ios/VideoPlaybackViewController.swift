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
    @IBAction func nextButton(_ sender: Any) {
        self.performSegue(withIdentifier: "showUploadDetails", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is UploadDetailsViewController
        {
            if let vc = segue.destination as? UploadDetailsViewController {
                if segue.identifier == "showUploadDetails" {
                    vc.videoDetails = videoURL
                }
            } else {
                self.showErrorContactingServer()
            }
        } else {
            self.showNoVideo()
        }
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
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        isDismissed = true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        isDismissed = false
        babaPlayer()
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
        performSegue(withIdentifier: "showUploadDetails", sender: self)
    }
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
    func showNoVideo() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "What?", message: "There's no video! How did this happen????", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "bruh moment", style: UIAlertAction.Style.default, handler: nil))

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

}
