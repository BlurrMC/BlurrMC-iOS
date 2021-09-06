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
    var videoNode: ASVideoNode
    
    required init(with videoUrl: URL, videoId: String, doesParentHaveTabBar: Bool, firstVideo: Bool, indexPath: IndexPath, reported: Bool, watchingPreference: WatchingPreference, shouldShowPreferences: Bool) {
        self.videoNode = ASVideoNode()
        super.init()
        if reported != true {
            self.videoNode.shouldAutoplay = true
            self.videoNode.shouldAutorepeat = true
            self.videoNode.muted = false
            self.videoNode.gravity = AVLayerVideoGravity.resizeAspect.rawValue
            DispatchQueue.main.async {
                self.videoNode.asset = AVAsset(url: videoUrl)
            }
            self.addSubnode(self.videoNode)
        }
        
        // Overlays:
        DispatchQueue.main.async {
            // Side bar overlay
            let overlay = ChannelVideoOverlayView()
            overlay.videoId = videoId
            overlay.videoUrl = videoUrl
            overlay.delegate = self.delegate
            overlay.indexPath = indexPath
            
            // Description Overlay
            let overlay2 = DescriptionOverlayView()
            overlay.delegate2 = overlay2
            overlay2.reported = reported
            
            // Add views
            self.view.addSubview(overlay2) // description
            self.view.addSubview(overlay) // side bar
            
            // Side bar overlay constraints:
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 75).isActive = true
            overlay.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                              constant: -(overlay.bounds.width + 10)).isActive = true
            overlay.widthAnchor.constraint(equalToConstant: 40).isActive = true
            overlay.heightAnchor.constraint(equalToConstant: 239).isActive = true
            
            // Description overlay constraints:
            overlay2.translatesAutoresizingMaskIntoConstraints = false
            overlay2.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: -(overlay2.bounds.width / 2)).isActive = true
            overlay2.heightAnchor.constraint(equalToConstant: 45).isActive = true
            overlay2.widthAnchor.constraint(equalToConstant: 287).isActive = true
            overlay2.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                                             constant: -100).isActive = true

        }
        // Top Overlay
        if firstVideo == true && shouldShowPreferences == true {
            DispatchQueue.main.async {
                // Declare view
                let topOverlay = VideoWatchingPreference()
                topOverlay.delegate = self.delegate

                // Add view
                self.view.addSubview(topOverlay) // top overlay
                
                // Add constraints
                topOverlay.translatesAutoresizingMaskIntoConstraints = false
                topOverlay.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
                topOverlay.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
                topOverlay.heightAnchor.constraint(equalToConstant: 100).isActive = true
                topOverlay.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 75).isActive = true
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
