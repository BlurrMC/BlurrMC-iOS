//
//  DescriptionOverlayView.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/15/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class DescriptionOverlayView: UIView, ChannelVideoDescriptionDelegate {
    
    // MARK: Info for overlay view
    func didReceiveInfo(_ sender: ChannelVideoOverlayView, views: Int, description: String, publishdate: String) {
        videoDesc = description
        definedDescription = description
        self.views = views
        self.publishdate = publishdate
        updateDescription()
    }
    
    // MARK: XIB Name
    let kCONTENT_XIB_NAME = "DescriptionOverlay"
    
    // MARK: Variables
    var isItSwitched = Bool()
    var views = Int()
    var videoDesc = String()
    var definedDescription = String()
    var viewCount = String()
    var publishdate = String()
    
    // MARK: Outlets
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet var contentView: UIView!
    
    // MARK: Update Outlets
    func updateDescription() {
        switch isItSwitched {
        case true:
            DispatchQueue.main.async {
                self.videoDescription.text = String("\(self.publishdate) \n\(self.viewCount)")
            }
        case false:
            DispatchQueue.main.async {
                self.videoDescription.text = self.definedDescription
            }
        }
    }
    
    // MARK: Initialize
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
            // Send request for description
            let descriptiontap = UITapGestureRecognizer(target: self, action: #selector(self.descriptiontapFunction(_:)))
            DispatchQueue.main.async {
                self.videoDescription.addGestureRecognizer(descriptiontap)
            }
        }
    }
    
    // MARK: Description Tap
    @objc func descriptiontapFunction(_ sender:UITapGestureRecognizer) {
        descriptionTap()
    }
    
    // MARK: Video views + publish date
    func descriptionTap() {
        if isItSwitched == false {
            switch views {
            case _ where views > 1000 && views < 100000:
                self.viewCount = "\(self.views/1000).\((self.views/100)%10)k Views"
            case _ where views > 100000 && views < 1000000:
                self.viewCount = "\(self.views/1000)k Views "
            case _ where views > 1000000 && views < 100000000:
                self.viewCount = "\(self.views/1000000).\((self.views/1000)%10)M Views"
            case _ where views > 100000000:
                self.viewCount = "\(self.views/1000000)M Views"
            case _ where views == 1:
                self.viewCount = "\(self.views) View"
            default:
                self.viewCount = "\(self.views) Views"
            }
            isItSwitched = true
            DispatchQueue.main.async {
                self.updateDescription()
            }
        } else {
            definedDescription = videoDesc
            isItSwitched = false
            DispatchQueue.main.async {
                self.updateDescription()
            }
        }
    }
}
