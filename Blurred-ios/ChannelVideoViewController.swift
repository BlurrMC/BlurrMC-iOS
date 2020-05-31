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
    var videoString = String()
    
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
        babaPlayer()
        // Do any additional setup after loading the view.
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
    func viewWillAppear() {
        super.viewWillAppear(true)
        babaPlayer()
        isDismissed = false
    }
    func viewWillDisappear() {
        super.viewWillDisappear(true)
        videoString = ""
        avPlayer.pause()
        isDismissed = true
    }
    fileprivate var player: AVPlayer? {
        didSet { player?.play() }
    }
    deinit {
        guard let observer = playerObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    func babaPlayer() {
        let videoUrl = URL(string: "http://10.0.0.2:3000\(videoString)")!
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
    // Setup function to contact api for each video thumbnail to load it 
}
