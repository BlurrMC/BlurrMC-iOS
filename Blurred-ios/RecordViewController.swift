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

class RecordViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    
    

    @IBAction func galleryButtonPress(_ sender: Any) {
        openVideoGallery()
    }
    @IBAction func recordButtonPress(_ sender: Any) {
        startCapture()
    }
    @IBAction func recordBackButton(_ sender: Any) {
        // We can't have the dismiss because it brings you back to the authentication page to sign you in.
        // We could just implement a token when loading back into the tab bar section....
    }
    @IBOutlet weak var videoView: UIView!

    let cameraButton = UIView()

    let captureSession = AVCaptureSession()

    let movieOutput = AVCaptureMovieFileOutput()

    var previewLayer: AVCaptureVideoPreviewLayer!

    var activeInput: AVCaptureDeviceInput!
    

    var outputURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        if setupSession() {
            setupPreview()
            startSession()
        }

        videoView.addSubview(cameraButton)
        // Saves the video to gallery and then uploads that video from gallery. The user doesn't have to pick that they are uploading it from gallery though.
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
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!

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
            print("Error recording movie: \(error!.localizedDescription)")
        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "showVideo", sender: videoRecorded)
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
    // Use alamofire to upload video.
}
