//
//  ChannelVideoOverlayTouchUIDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/13/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol ChannelVideoOverlayTouchUIDelegate: AnyObject {
    func didChangeDescription(_ sender:ChannelVideoOverlayTouch,definedDescription:String)
    func didChangeHeartIcon(_ sender:ChannelVideoOverlayTouch,videoLiked:Bool)
    func didChangeAvatarUrl(_ sender:ChannelVideoOverlayTouch,avatarUrl:String)
    func didChangeLikeNumber(_ sender: ChannelVideoOverlayTouch,likeNumber:Int)
}
