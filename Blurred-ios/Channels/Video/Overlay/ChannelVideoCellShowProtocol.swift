//
//  ChannelVideoShowProtocol.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/14/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol ChannelVideoOverlayViewDelegate: AnyObject {
    func didTapChannel(_ sender:ChannelVideoOverlayView)
    func didTapComments(_ sender:ChannelVideoOverlayView)
}
