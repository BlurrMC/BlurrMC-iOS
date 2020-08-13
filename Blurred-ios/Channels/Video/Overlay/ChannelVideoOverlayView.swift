//
//  ChannelVideoOverlayViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/8/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke
import Alamofire

class ChannelVideoOverlayView: UIView, ChannelVideoOverlayTouchUIDelegate {
    func didChangeHeartIcon(_ sender: ChannelVideoOverlayTouch, videoLiked: Bool) {
        isVideoLiked = videoLiked
        changeHeartIcon()
    }
    
    func didChangeAvatarUrl(_ sender: ChannelVideoOverlayTouch, avatarUrl: String) {
        newAvatarUrl = avatarUrl
        changeChannelAvatar()
    }
    
    func didChangeLikeNumber(_ sender: ChannelVideoOverlayTouch, likeNumber: Int) {
        newLikeNumber = likeNumber
        changeLikeCount()
    }
    
    func didChangeDescription(_ sender: ChannelVideoOverlayTouch, definedDescription: String) {
        DefinedDescription = definedDescription
        updateDescription()
    }
    
    
    // MARK: Variables
    var DefinedDescription = String()
    var isVideoLiked = Bool()
    var newAvatarUrl = String()
    var newLikeNumber = Int()
    var videoId = Int()
    
    
    let kCONTENT_XIB_NAME = "ChannelVideoOverlay"
    
    // MARK: Update Outlets
    // Must be called by main thread
    func updateDescription() {
        videoDescription.text = DefinedDescription
    }
    func changeHeartIcon() {
        if isVideoLiked == true {
            videoLike.image = UIImage(systemName: "heart.fill")
            videoLike.tintColor = UIColor.systemRed
        } else {
            videoLike.image = UIImage(systemName: "heart")
            videoLike.tintColor = UIColor.lightGray
        }
    }
    func changeChannelAvatar() {
        guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {
            return
        }
        let avatarUrl = URL(string: "\(self.newAvatarUrl)")
        Nuke.loadImage(with: avatarUrl ?? imageURL, into: videoChannel)
    }
    func changeLikeCount() {
        switch newLikeNumber {
        case _ where newLikeNumber > 1000 && newLikeNumber < 100000:
            self.videoLikeCount.text = "\(self.newLikeNumber/1000).\((self.newLikeNumber/100)%10)k"
        case _ where newLikeNumber > 100000 && newLikeNumber < 1000000:
            self.videoLikeCount.text = "\(self.newLikeNumber/1000)k"
        case _ where newLikeNumber > 1000000 && newLikeNumber < 100000000:
            self.videoLikeCount.text = "\(self.newLikeNumber/1000000).\((self.newLikeNumber/1000)%10)M"
        case _ where newLikeNumber > 100000000:
            self.videoLikeCount.text = "\(self.newLikeNumber/1000000)M"
        case _ where newLikeNumber == 1:
            self.videoLikeCount.text = "\(self.newLikeNumber)"
        default:
            self.videoLikeCount.text = "\(self.newLikeNumber)"
        }
    }
    
    @IBOutlet var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)
        contentView.fixInView(self)
        DispatchQueue.global(qos: .background).async {
            let touches = ChannelVideoOverlayTouch(videoId: self.videoId)
            touches.delegate = self
            touches.sendRequest()
            touches.sendCheckLikeRequest()
            touches.checkLikeCount()
            
            let tapp = UITapGestureRecognizer(target: self, action: #selector(self.tappFunction))
            let tappp = UITapGestureRecognizer(target: self, action: #selector(self.tapppFunction))
            let liketap = UITapGestureRecognizer(target: self, action: #selector(touches.liketapFunction))
            let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(touches.descriptiontapFunction))
            DispatchQueue.main.async {
                self.videoDescription.addGestureRecognizer(descriptiontap)
                self.videoComment.addGestureRecognizer(tappp)
                self.videoChannel.addGestureRecognizer(tapp)
                self.videoLike.addGestureRecognizer(liketap)
            }
        }
    }
    
    // MARK: Show user channel tap
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        let coder = NSCoder()
        let controller = ChannelVideoViewController(coder: coder)
        controller?.showUserChannel()
    }
    
    // MARK: Show Video Comments Tap
    @objc func tapppFunction(sender:UITapGestureRecognizer) {
        let coder = NSCoder()
        let controller = ChannelVideoViewController(coder: coder)
        controller?.showVideoComments()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Outlets
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet weak var videoShare: UIImageView!
    @IBOutlet weak var videoLikeCount: UILabel!
    @IBOutlet weak var videoLike: UIImageView!
    @IBOutlet weak var videoComment: UIImageView!
    @IBOutlet weak var videoChannel: UIImageView!
    
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
