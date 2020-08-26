//
//  DescriptionOverlayDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/15/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol ChannelVideoDescriptionDelegate: AnyObject {
    func didReceiveInfo(_ sender:ChannelVideoOverlayView, views:Int, description:String, publishdate:String)
}
