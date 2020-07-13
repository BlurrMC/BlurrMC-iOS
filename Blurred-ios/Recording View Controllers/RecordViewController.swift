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
    var timer = Timer()
    var usingFrontCamera = false
    
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
    @IBAction func flipCamera(_ sender: Any) {
        frontOrBackCamera()
    }
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }

    func getBackCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
    }
    @objc func timerAction() {
        stopRecording()
    }
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
    @IBOutlet weak var flipCameraIcon: UIButton!
    @IBAction func recordBackButton(_ sender: Any) {
        // self.dismiss(animated: true, completion: nil) This does not work for some reason (bug?)
    }
    @IBOutlet weak var videoView: UIView!

    let cameraButton = UIView()

    let captureSession = AVCaptureSession()

    let movieOutput = AVCaptureMovieFileOutput()

    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    var activeInput: AVCaptureDeviceInput!
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 10.0
    var lastZoomFactor: CGFloat = 1.0
    

    var outputURL: URL!
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        // guard let device = captureDevice else { return }
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { showNoCamera(); isCameraThere = false; return }
        

        // Return zoom value between the minimum and maximum zoom values
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // No tab bar for you!
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        videoView.addGestureRecognizer(pinchRecognizer)
        videoView.isUserInteractionEnabled = true
        
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
    var isCameraFlipped: Bool = false
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
    func setupMicrophone() {
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
        
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
    func setupSession() -> Bool {

        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        //captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        // Setup Camera
        //guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else { showNoCamera(); isCameraThere = false; return true }
        //let front = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
        //let back = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
        
            
            //let input = try AVCaptureDeviceInput(device: camera)
            
            //if captureSession.canAddInput(input) {
            //    captureSession.addInput(input)
            //    activeInput = input
            //}
        
        frontOrBackCamera()
        // Setup Microphone

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
    func prepareRecording() {
        let connection = movieOutput.connection(with: AVMediaType.video)
       
       
       if ((connection?.isVideoOrientationSupported) != nil) {
            connection?.videoOrientation = currentVideoOrientation()
        }
       if ((connection?.isVideoStabilizationSupported) != nil) {
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
    }
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
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
         }
        timer.invalidate()
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            // image = videoMuffinString
            outputURL = image
            let videoRecorded = outputURL! as URL
            dismiss(animated: true) {
                self.performSegue(withIdentifier: "showVideo", sender: videoRecorded)
            }
        } else {
            self.showUnkownError()
        }
        self.dismiss(animated: true, completion: nil)
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
    func showUnkownError() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "We don't know what happend wrong here! Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Fine", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
