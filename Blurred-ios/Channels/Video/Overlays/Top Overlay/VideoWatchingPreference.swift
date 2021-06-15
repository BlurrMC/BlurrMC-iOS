//
//  VideoWatchingPreference.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/10/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit

class VideoWatchingPreference: UIView {

    @IBOutlet weak var trendingOutlet: UIButton!
    @IBOutlet weak var followingOutlet: UIButton!
    weak var delegate: ChannelVideoOverlayViewDelegate?
    
    
    @IBAction func followingTap(_ sender: Any) {
        self.followingOutlet.tintColor = UIColor.systemRed
        self.trendingOutlet.tintColor = UIColor.label
        delegate?.switchedPreference(newPreference: .following)
    }
    
    @IBAction func trendingTap(_ sender: Any) {
        self.trendingOutlet.tintColor = UIColor.systemRed
        self.followingOutlet.tintColor = UIColor.label
        delegate?.switchedPreference(newPreference: .trending)
    }
    
}
enum WatchingPreference {
    case following
    case trending
}
