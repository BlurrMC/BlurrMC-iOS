//
//  VideoPlaybaackViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/18/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//
import AVFoundation
import UIKit

class VideoPlaybackViewController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    var videoURL: URL!
    override func viewDidLoad() {
        super.viewDidLoad()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer.replaceCurrentItem(with: playerItem)

        avPlayer.play()

        // Do any additional setup after loading the view.
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
