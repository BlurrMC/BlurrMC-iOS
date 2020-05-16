//
//  RecordViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import MobileCoreServices

class RecordViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    

    @IBAction func galleryButtonPress(_ sender: Any) {
        openVideoGallery()
    }
    @IBAction func recordButtonPress(_ sender: Any) {
    }
    @IBAction func recordBackButton(_ sender: Any) {
        // We can't have the dismiss because it brings you back to the authentication page to sign you in.
        // We could just implement a token when loading back into the tab bar section....
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        // Saves the video to gallery and then uploads that video from gallery. The user doesn't have to pick that they are uploading it from gallery though.
    }
    func openVideoGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoMaximumDuration = 7
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}
