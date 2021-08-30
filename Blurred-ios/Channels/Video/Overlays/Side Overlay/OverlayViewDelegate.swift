//
//  ChannelVideoShowProtocol.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/14/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation
import Nuke

protocol ChannelVideoOverlayViewDelegate: AnyObject {
    func didTapChannel(_ view:ChannelVideoOverlayView, videousername: String, resizedImageProcessor: [ImageProcessing], isReported: Bool, isBlocked: Bool, name: String)
    func didTapComments(_ view:ChannelVideoOverlayView, videoid: String)
    func didTapShare(_ view:ChannelVideoOverlayView, videoUrl: String, videoId: String)
    func didPressReport(videoId: String, videoIndex: IndexPath)
    func switchedPreference(newPreference: WatchingPreference)
    func willPresentAlert(alertController: UIAlertController)
}
extension ChannelVideoOverlayViewDelegate {
    func switchedPreference(newPreference: WatchingPreference) {
        
    }
}
