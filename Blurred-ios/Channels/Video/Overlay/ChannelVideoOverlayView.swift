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

class ChannelVideoOverlayView: UIView {
    
    // MARK: Variables
    var DefinedDescription = String()
    var isVideoLiked = Bool()
    var avatarUrl = String()
    var likeNumber = Int()
    
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
        let avatarUrl = URL(string: "\(self.avatarUrl)")
        Nuke.loadImage(with: avatarUrl ?? imageURL, into: videoChannel)
    }
    func changeLikeCount() {
        switch likeNumber {
        case _ where likeNumber > 1000 && likeNumber < 100000:
            self.videoLikeCount.text = "\(self.likeNumber/1000).\((self.likeNumber/100)%10)k"
        case _ where likeNumber > 100000 && likeNumber < 1000000:
            self.videoLikeCount.text = "\(self.likeNumber/1000)k"
        case _ where likeNumber > 1000000 && likeNumber < 100000000:
            self.videoLikeCount.text = "\(self.likeNumber/1000000).\((self.likeNumber/1000)%10)M"
        case _ where likeNumber > 100000000:
            self.videoLikeCount.text = "\(self.likeNumber/1000000)M"
        case _ where likeNumber == 1:
            self.videoLikeCount.text = "\(self.likeNumber)"
        default:
            self.videoLikeCount.text = "\(self.likeNumber)"
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
        let tapp = UITapGestureRecognizer(target: self, action: #selector(self.tappFunction))
        let tappp = UITapGestureRecognizer(target: self, action: #selector(self.tapppFunction))
        let liketap = UITapGestureRecognizer(target: self, action: #selector(self.liketapFunction))
        let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(self.descriptiontapFunction))
        videoDescription.addGestureRecognizer(descriptiontap)
        videoComment.addGestureRecognizer(tappp)
        videoChannel.addGestureRecognizer(tapp)
        videoLike.addGestureRecognizer(liketap)
    }
    
    // MARK: Description Tap
    @objc func descriptiontapFunction(sender:UITapGestureRecognizer) {
        let classs = ChannelVideoOverlayTouch()
        classs.descriptionTap()
    }
    
    // MARK: Like Tap
    @objc func liketapFunction(sender:UITapGestureRecognizer) {
        let classs = ChannelVideoOverlayTouch()
        classs.likeTapFunction()
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
