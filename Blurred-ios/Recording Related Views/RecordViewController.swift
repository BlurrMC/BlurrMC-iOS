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

// MARK: Maybe change camera method to CameraManager
class RecordViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: Variables
    var timer = Timer()
    var usingFrontCamera = Bool()
    var isCameraThere = Bool()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    var activeInput: AVCaptureDeviceInput?
    var lastZoomFactor: CGFloat = 1.0
    var outputURL: URL!
    var isCameraFlipped: Bool = false
    
    // MARK: Lets
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 10.0
    let cameraButton = UIView()
    let captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()

    
    // MARK: Outlets
    @IBOutlet weak var flipCameraIcon: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "frontCamera")!, accessibility: .whenUnlocked)
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if usingFrontCamera == true {
            usingFrontCamera = false
        } else if usingFrontCamera == false {
            usingFrontCamera = true
        }
        frontOrBackCamera()
        prepareRecording()
    }
    
    
    // MARK: Flip Camera Button Press
    @IBAction func flipCamera(_ sender: Any) {
        try? self.myValet.setString("\(usingFrontCamera)", forKey: "frontCamera")
        frontOrBackCamera()
    }
    
    
    // MARK: Get Front Camera
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }

    // MARK: Get Back Camera
    func getBackCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
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
        // MARK: Zooming on front camera or back camera
        if usingFrontCamera == true {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else { return }
            func minMaxZoom(_ factor: CGFloat) -> CGFloat {
                return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
            }

            func update(scale factor: CGFloat) {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }
                    device.videoZoomFactor = factor
                } catch {
                    print("\(error.localizedDescription)")
                }
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
        } else {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { showNoCamera(); isCameraThere = false; return }
            func minMaxZoom(_ factor: CGFloat) -> CGFloat {
                return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
            }

            func update(scale factor: CGFloat) {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }
                    device.videoZoomFactor = factor
                } catch {
                    print("\(error.localizedDescription)")
                }
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
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        videoView.addGestureRecognizer(pinchRecognizer)
        videoView.isUserInteractionEnabled = true
        originalFlip()
        if setupSession() {
            setupPreview()
            startSession()
        }

        videoView.addSubview(cameraButton)
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
    
    
    // MARK: Setup the video preview
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = videoView.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.addSublayer(previewLayer)
    }
    
    
    // MARK: Flip the camera
    func frontOrBackCamera() {
        usingFrontCamera = !usingFrontCamera
        do{
            if(usingFrontCamera){
                captureDevice = getFrontCamera()
            }else{
                captureDevice = getBackCamera()
            }
            let captureDeviceInput1 = try AVCaptureDeviceInput(device: captureDevice)
            if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    captureSession.removeInput(input)
                }
            }
            if captureSession.canAddInput(captureDeviceInput1) {
                captureSession.addInput(captureDeviceInput1)
                activeInput = captureDeviceInput1
            }
            setupMicrophone()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: Setup the microphone
    func setupMicrophone() {
        guard let microphone = AVCaptureDevice.default(for: AVMediaType.audio) else { return }
        
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if captureSession.canAddInput(micInput) {
                    captureSession.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
                return
            }
    }
    
    
    // MARK: Setup session (for recording)
    func setupSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        frontOrBackCamera()
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        return true
    }

    
    // MARK: Setup Capture Mode
    func setupCaptureMode(_ mode: Int) {
    }
    
    
    // MARK: Start the session (for recording)
    func startSession() {

        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    
    // MARK: Stop the session (for recording)
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    
    // MARK: The Video Queue
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    
    // MARK: Check the orientation
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
    
    
    // MARK: Prepare for recording
    func prepareRecording() {
        let connection = movieOutput.connection(with: AVMediaType.video)
       
       
       if ((connection?.isVideoOrientationSupported) != nil) {
            connection?.videoOrientation = currentVideoOrientation()
        }
       if ((connection?.isVideoStabilizationSupported) != nil) {
            connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
        }

        let device = activeInput?.device

        if ((device?.isSmoothAutoFocusSupported) != nil) {

            do {
                try device?.lockForConfiguration()
                device?.isSmoothAutoFocusEnabled = false
                device?.unlockForConfiguration()
            } catch {
               print("Error setting configuration: \(error)")
            }

        }
    }
    
    
    // MARK: Start the recording
    func startRecording() {
     if movieOutput.isRecording == false {

         
        timer = Timer.scheduledTimer(timeInterval: 7.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
         //EDIT2: And I forgot this
         outputURL = tempURL()
        
        self.movieOutput.startRecording(to: self.outputURL, recordingDelegate: self)
         

         }
         else {
             stopRecording()
         }
    }
    
    
    // MARK: Stop the recording
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
         }
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
    
    
    // MARK: Output Video
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {

        if (error != nil) {
            print("Error: \(error!.localizedDescription)")
        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "showVideo", sender: videoRecorded)
        }
    }
    
    
    // MARK: No Camera Alert
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

    
    // MARK: File Output (For video)
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if (error != nil) {

            print("Error recording movie: \(error!.localizedDescription)")

        } else {

            let videoRecorded = outputURL! as URL

            performSegue(withIdentifier: "showVideo", sender: videoRecorded)

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
