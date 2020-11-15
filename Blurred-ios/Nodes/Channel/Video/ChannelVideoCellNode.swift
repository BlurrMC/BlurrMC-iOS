//
//  ChannelVideoCellNode.swift
//  Blurred-ios
//
//  Created by Martin Velev on 7/30/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ChannelVideoCellNode: ASCellNode {
    
    // MARK: Delegates
    weak var delegate: ChannelVideoOverlayViewDelegate?
    
    // MARK: Variables
    var videoNode = ASVideoNode()

    required init(with videoUrl: URL, videoId: Int, doesParentHaveTabBar: Bool) {
        self.videoNode = ASVideoNode()
        super.init()
        self.addSubnode(self.videoNode)
        self.videoNode.shouldAutoplay = true
        self.videoNode.shouldAutorepeat = true
        self.videoNode.muted = false
        self.videoNode.gravity = AVLayerVideoGravity.resizeAspect.rawValue
        DispatchQueue.main.async {
            self.videoNode.asset = AVAsset(url: videoUrl)
        }
        self.addSubnode(self.videoNode)
        DispatchQueue.main.async() {
            let overlay = ChannelVideoOverlayView()
            overlay.videoId = videoId
            overlay.videoUrl = videoUrl
            overlay.delegate = self.delegate
            overlay.frame = CGRect(x: 329, y: 284, width: 40, height: 239)
            self.view.addSubview(overlay)
            DispatchQueue.global(qos: .default).async {
                switch doesParentHaveTabBar {
                case true:
                    DispatchQueue.main.async {
                        let overlay2 = DescriptionOverlayView()
                        overlay.delegate2 = overlay2
                        overlay2.frame = CGRect(x: 40, y: 565, width: 287, height: 45)
                        self.view.addSubview(overlay2)
                    }
                case false:
                    DispatchQueue.main.async {
                        let overlay2 = DescriptionOverlayView()
                        overlay.delegate2 = overlay2
                        overlay2.frame = CGRect(x: 40, y: 614, width: 287, height: 45)
                        self.view.addSubview(overlay2)
                    }
                }
            }
        }
        
    }
    
    // MARK: Layout spec
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratio = UIScreen.main.bounds.height / UIScreen.main.bounds.width
        let ratioSpec = ASRatioLayoutSpec(ratio:ratio, child:self.videoNode)
        return ratioSpec
    }
    
  
}
