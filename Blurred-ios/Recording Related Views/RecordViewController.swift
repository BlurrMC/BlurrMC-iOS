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
import Alamofire
import Valet
import NextLevel

// MARK: Maybe change camera method to CameraManager
class RecordViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // MARK: Variables & Constants
    var timer = Timer()
    var flashMode = String()
    var usingFrontCamera = Bool()
    var isCameraThere = Bool()
    var lastZoomFactor: CGFloat = 1.0
    var outputURL: URL!
    var isCameraFlipped: Bool = false
    internal var _panStartPoint: CGPoint = .zero
    internal var _panStartZoom: CGFloat = 1
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 15.0
    let cameraButton = UIView()

    
    // MARK: Outlets
    @IBOutlet weak var flipCameraIcon: UIButton!
    @IBOutlet var videoView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "frontCamera")!, accessibility: .whenUnlocked)
    let flashValet = Valet.valet(with: Identifier(nonEmpty: "flash")!, accessibility: .whenUnlocked)
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if usingFrontCamera == true {
            switch NextLevel.shared.devicePosition {
            case .back:
                NextLevel.shared.flipCaptureDevicePosition()
            case .front:
                break
            case .unspecified:
                break
            @unknown default:
                break
            }
        } else if usingFrontCamera == false {
            switch NextLevel.shared.devicePosition {
            case .back:
                break
            case .front:
                NextLevel.shared.flipCaptureDevicePosition()
            case .unspecified:
                break
            @unknown default:
                break
            }
        }
        NextLevel.requestAuthorization(forMediaType: AVMediaType.video, completionHandler: {_,_ in
            NextLevel.requestAuthorization(forMediaType: AVMediaType.audio, completionHandler: {_,_ in
                try? NextLevel.shared.start()
            })
        })
        
    }
    
    // MARK: Setup Camera Preview
    func setupCameraPreview() {
        let screenBounds = UIScreen.main.bounds
        self.videoView = UIView(frame: screenBounds)
        if let previewView = self.videoView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.backgroundColor = UIColor.black
            NextLevel.shared.previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(NextLevel.shared.previewLayer)
            let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
            let flipGesture = UITapGestureRecognizer(target: self, action: #selector(flipVideo))
            flipGesture.numberOfTapsRequired = 2
            previewView.addGestureRecognizer(flipGesture)
            previewView.addGestureRecognizer(pinchRecognizer)
            previewView.isUserInteractionEnabled = true
            self.view.insertSubview(previewView, at: 1)
        }
    }
    
    
    // MARK: Flip Camera Button Press
    @IBAction func flipCamera(_ sender: Any) {
        flipVideo()
    }
    
    @objc func flipVideo() {
        try? self.myValet.setString("\(usingFrontCamera)", forKey: "frontCamera")
        NextLevel.shared.flipCaptureDevicePosition()
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
        NextLevel.shared.stop()
    }
    
    
    // MARK: Timer Action
    @objc func timerAction() {
        stopRecording()
    }
    
    
    // MARK: Gallery Button Press
    @IBAction func galleryButtonPress(_ sender: Any) {
        openVideoGallery()
    }
    
    
    // MARK: Record Button Pressed Up
    @IBAction func recordButtonReleased(_ sender: Any) {
        stopRecording()
    }
    
    // MARK: Record Button Pressed Down
    @IBAction func recordButtonPress(_ sender: Any) {
        startCapture()
    }
    
    
    // MARK: Back Button Press
    @IBAction func recordBackButton(_ sender: Any) {
    }
    
    
    // MARK: Pinch Gesture
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), 15)
        }

        func update(scale factor: CGFloat) {
            NextLevel.shared.videoZoomFactor = Float(factor)
        }

        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)

        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }

    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        self.dismissButton.layer.zPosition = 10
        
        
        originalFlip()
        
        videoView.addSubview(cameraButton)
        
        // New:
        setupCameraPreview()
        NextLevel.shared.videoConfiguration.bitRate = 6000000
        NextLevel.shared.videoConfiguration.codec = AVVideoCodecType.h264
        NextLevel.shared.videoConfiguration.preset = AVCaptureSession.Preset.high
        NextLevel.shared.audioConfiguration.bitRate = 96000
    }
    
    
    // MARK: Get the original position of camera
    func originalFlip() {
        let frontOrBack: String?  = try? myValet.string(forKey: "frontCamera")
        if frontOrBack == nil {
            usingFrontCamera = false
        } else if frontOrBack == "true" {
            usingFrontCamera = true
        } else if frontOrBack == "false" {
            usingFrontCamera = false
        }
    }

    
    // MARK: Start Capturing
    @objc func startCapture() {
        startRecording()
    }
    
    
    // MARK: Temp URL For Video
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }

        return nil
    }
    
    
    // MARK: Pass Info Through Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? VideoPlaybackViewController
        vc?.videoURL = sender as? URL
    }
    
    
    // MARK: Start the recording
    func startRecording() {
        if NextLevel.shared.isRecording == false {
            timer = Timer.scheduledTimer(timeInterval: 7.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
            NextLevel.shared.record()
        } else {
            stopRecording()
        }
    }
    
    
    // MARK: Stop the recording
    func stopRecording() {
        if NextLevel.shared.isRecording == true {
            if let session = NextLevel.shared.session {
                if let clip = session.lastClipUrl {
                    self.outputURL = clip
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "showVideo", sender: clip)
                    }
                } else if session.currentClipHasStarted {
                    session.endClip(completionHandler: {(clip, error) in
                        if error == nil {
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "showVideo", sender: clip?.url)
                            }
                        } else {
                            print("error code: 29fak03, error saving video: \(error?.localizedDescription ?? "")")
                        }
                    })
                }

            }
        }
        NextLevel.shared.pause()
        timer.invalidate()
    }
    
    
    // MARK: Image Picker Controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            // image = videoMuffinString
            outputURL = image
            let videoRecorded = outputURL! as URL
            dismiss(animated: true) {
                self.performSegue(withIdentifier: "showVideo", sender: videoRecorded)
            }
        } else {
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Open gallery for uploading from gallery
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
