//
//  ChannelVideoShowProtocol.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/14/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol ChannelVideoOverlayViewDelegate: AnyObject {
    func didTapChannel(_ view:ChannelVideoOverlayView, videousername: String)
    func didTapComments(_ view:ChannelVideoOverlayView, videoid: Int)
    func didTapShare(_ view:ChannelVideoOverlayView, videoUrl: String)
}
