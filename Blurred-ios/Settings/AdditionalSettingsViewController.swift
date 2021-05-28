//
//  AdditionalSettingsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/28/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import AVFoundation
import Valet

class AdditionalSettingsViewController: UIViewController {
    
    let cameraSettings = Valet.valet(with: Identifier(nonEmpty: "cameraSettings")!, accessibility: .whenUnlocked)
    
    @IBOutlet weak var telephotoLensSwitch: UISwitch!
    @IBOutlet weak var ultraWideAngleSwitch: UISwitch!
    var telephotoLens: Bool = false
    var ultraWideAngle: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        checkForCameraTypes()
        self.navigationItem.title = "Addtional Settings"
        telephotoLensSwitch.addTarget(self, action: #selector(self.telephotoSwitchHasChanged(telephotoSwitch:)), for: .valueChanged)
        ultraWideAngleSwitch.addTarget(self, action: #selector(self.ultraWideSwitchHasChanged(ultraWideSwitch:)), for: .valueChanged)
        let telephotoSetting = try? cameraSettings.string(forKey: "telephoto")
        let ultraWideSetting = try? cameraSettings.string(forKey: "ultrawide")
        if telephotoSetting == "on" {
            self.telephotoLensSwitch.isOn = true
        }
        if ultraWideSetting == "on" {
            self.ultraWideAngleSwitch.isOn = true
        }
    }

    // MARK: Checks for the multiple camera types
    func checkForCameraTypes() {
        if checkForUltraWideAngle() != nil {
            self.ultraWideAngle = true
        } else {
            self.ultraWideAngleSwitch.isEnabled = false
        }
        if checkForTelephoto() != nil {
            self.telephotoLens = true
        } else {
            self.telephotoLensSwitch.isEnabled = false
        }
    }
    
    
    // MARK: Checks for the ultrawide lens
    func checkForUltraWideAngle() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: AVMediaType.video, position: .back) {
            return device
        } else {
            return nil
        }
    }
    
    
    // MARK: Checks for the telephoto lens
    func checkForTelephoto() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: AVMediaType.video, position: .back) {
            return device
        } else {
            return nil
        }
    }
    
    
    // MARK: Tracks when the telephoto camera switch value has changed
    @objc func telephotoSwitchHasChanged(telephotoSwitch: UISwitch) {
        if telephotoSwitch.isOn {
            try? cameraSettings.setString("on", forKey: "telephoto")
        } else {
            try? cameraSettings.setString("off", forKey: "telephoto")
        }
    }
    
    // MARK: Tracks when the ultrawide camera switch value has changed
    @objc func ultraWideSwitchHasChanged(ultraWideSwitch: UISwitch) {
        if ultraWideSwitch.isOn {
            try? cameraSettings.setString("on", forKey: "ultrawide")
        } else {
            try? cameraSettings.setString("off", forKey: "ultrawide")
        }
    }
}
