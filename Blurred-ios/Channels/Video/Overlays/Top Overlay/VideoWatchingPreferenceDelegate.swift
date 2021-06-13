//
//  VideoWatchingPreferenceDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/10/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import Foundation

protocol VideoWatchingPreferenceDelegate: AnyObject {
    func switchedPreference(newPreference: WatchingPreference)
}
