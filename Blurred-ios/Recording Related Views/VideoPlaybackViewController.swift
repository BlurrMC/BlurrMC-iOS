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
    
    // MARK: Outlets
    @IBOutlet weak var previewView: UIView!
    
    
    // MARK: Lets
    let avPlayer = AVPlayer()
    
    
    // MARK: Variables
    var avPlayerLayer: AVPlayerLayer!
    var isDismissed: Bool = false
    fileprivate var player: AVPlayer? {
        didSet { player?.play() }
    }
    fileprivate var playerObserver: Any?
    var videoURL: URL!
    var doubleTap : Bool! = false
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Deinit
    deinit {
        guard let observer = playerObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: Back Button Tap
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        isDismissed = true
        avPlayer.pause()
    }
    
    
    // MARK: Next button Tap
    @IBAction func nextButton(_ sender: Any) {
        self.performSegue(withIdentifier: "showUploadDetails", sender: self)
    }
    
    
    // MARK: Pass info through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is UploadDetailsViewController
        {
            if let vc = segue.destination as? UploadDetailsViewController {
                if segue.identifier == "showUploadDetails" {
                    vc.videoDetails = videoURL
                }
            } else {
                return
            }
        } else {
            popupMessages().showMessage(title: "what", message: "i dont know what to put here", alertActionTitle: "okay?", viewController: self)
        }
    }
    
    
    // MARK: Did Receive Memory Warning
    override func didReceiveMemoryWarning() {
        avPlayerLayer = nil
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        babaPlayer()
        self.previewView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(VideoPlaybackViewController.tapFunction))
        previewView.addGestureRecognizer(tap)
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        isDismissed = true
        avPlayer.pause()
        avPlayerLayer = nil
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        isDismissed = false
        babaPlayer()
    }
    
    
    // MARK: Play the reecorded video
    func babaPlayer() {
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()
        guard let videoUrl = videoURL else { return }
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
    
    
    // MARK: Done Button
    @IBAction func doneButton(_ sender: Any) {
        performSegue(withIdentifier: "showUploadDetails", sender: self)
    }
    
    
    // MARK: Tap Function Gesture
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        if (doubleTap) {
            doubleTap = false
            avPlayer.play()
        } else {
            avPlayer.pause()
            doubleTap = true
        }
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }

}
