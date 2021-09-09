//
//  VideoWatchingPreference.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/10/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit

class VideoWatchingPreference: UIView {

    
    // MARK: XIB Name
    let kCONTENT_XIB_NAME = "VideoWatchingPreference"
    
    // MARK: Variables
    @IBOutlet weak var trendingOutlet: UIButton!
    @IBOutlet weak var followingOutlet: UIButton!
    @IBOutlet var contentView: UIView!
    weak var delegate: ChannelVideoOverlayViewDelegate?
    var watchingPreference: WatchingPreference = .following
    
    // MARK: Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(frame: CGRect, watchingPreference: WatchingPreference) {
        self.watchingPreference = watchingPreference
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
        switch watchingPreference {
        case .following:
            self.followingOutlet.tintColor = .systemRed
            self.trendingOutlet.tintColor = .label
        case .trending:
            self.trendingOutlet.tintColor = .systemRed
            self.followingOutlet.tintColor = .label
        }
    }
    
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
