//
//  VideoWatchingPreference.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/10/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit

class VideoWatchingPreference: UIView {

    weak var delegate: VideoWatchingPreferenceDelegate?

}
enum WatchingPreference {
    case following
    case trending
}
