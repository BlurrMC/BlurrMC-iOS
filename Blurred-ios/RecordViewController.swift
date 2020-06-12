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

// This doesn't work and I don't know why and I want to die and I hate you.

class RecordViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    
    var isCameraThere = Bool()
    @IBAction func galleryButtonPress(_ sender: Any) {
        openVideoGallery()
    }
    @IBAction func recordButtonReleased(_ sender: Any) {
        stopRecording()
    }
    @IBAction func recordButtonPress(_ sender: Any) {
        startCapture()
    }
    func camera() {
        
    }
    @IBAction func recordBackButton(_ sender: Any) {
        // self.dismiss(animated: true, completion: nil) This does not work for some reason (bug?)
    }
    @IBOutlet weak var videoView: UIView!

    let cameraButton = UIView()

    let captureSession = AVCaptureSession()

    let movieOutput = AVCaptureMovieFileOutput()

    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    @IBAction func pinchToZoom(_ sender: UIPinchGestureRecognizer) {

        guard let device = captureDevice else { return }

        if sender.state == .changed {

            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 5.0

            do {

                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                let desiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))

            } catch {
                print(error)
            }
        }
    }

    var activeInput: AVCaptureDeviceInput!
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    

    var outputURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinchToZoom(_:)))
        self.videoView.addGestureRecognizer(pinchRecognizer)
        if setupSession() {
            setupPreview()
            startSession()
        }

        videoView.addSubview(cameraButton)
    }
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = videoView.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.addSublayer(previewLayer)
    }
    func setupSession() -> Bool {

        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        // Setup Camera
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else { showNoCamera(); isCameraThere = false; return true }
        

        do {

            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
    
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }


        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        return true
    }

    func setupCaptureMode(_ mode: Int) {
        // Video Mode

    }
    func startSession() {

        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
       var orientation: AVCaptureVideoOrientation

       switch UIDevice.current.orientation {
           case .portrait:
               orientation = AVCaptureVideoOrientation.portrait
           case .portraitUpsideDown:
               orientation = AVCaptureVideoOrientation.portraitUpsideDown
           default:
                orientation = AVCaptureVideoOrientation.portrait
        }

        return orientation
    }
    @objc func startCapture() {

        startRecording()

    }
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }

        return nil
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? VideoPlaybackViewController
        vc?.videoURL = sender as? URL
    }
    func startRecording() {

     if movieOutput.isRecording == false {

         let connection = movieOutput.connection(with: AVMediaType.video)

         if (connection?.isVideoOrientationSupported)! {
             connection?.videoOrientation = currentVideoOrientation()
         }

         if (connection?.isVideoStabilizationSupported)! {
             connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
         }

         let device = activeInput.device

         if (device.isSmoothAutoFocusSupported) {

             do {
                 try device.lockForConfiguration()
                 device.isSmoothAutoFocusEnabled = false
                 device.unlockForConfiguration()
             } catch {
                print("Error setting configuration: \(error)")
             }

         }

         //EDIT2: And I forgot this
         outputURL = tempURL()
         movieOutput.startRecording(to: outputURL, recordingDelegate: self)

         }
         else {
             stopRecording()
         }

    }
    func stopRecording() {

        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
         }
    }
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {

        if (error != nil) {
            print("Error: \(error!.localizedDescription)")
        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "showVideo", sender: videoRecorded)
        }
    }
    func showNoCamera() {
        let alert = UIAlertController(title: "Error", message: "No camera is connected. What phone are you on?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK?", style: UIAlertAction.Style.default, handler: { action in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToTabBar", sender: self)
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if (error != nil) {

            print("Error recording movie: \(error!.localizedDescription)")

        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "showVideo", sender: videoRecorded)

        }

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
