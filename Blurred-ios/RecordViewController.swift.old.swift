//
//  RecordViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var qrCodeFrameView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
                captureButton.clipsToBounds = true
                
                // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter
                guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                    fatalError("No video device found")
                }
                
                do {
                    // Get an instance of the AVCaptureDeviceInput class using the previous deivce object
                    let input = try AVCaptureDeviceInput(device: captureDevice)
                    
                    // Initialize the captureSession object
                    captureSession = AVCaptureSession()
                    
                    // Set the input devcie on the capture session
                    captureSession?.addInput(input)
                    
                    // Get an instance of ACCapturePhotoOutput class
                    capturePhotoOutput = AVCapturePhotoOutput()
                    capturePhotoOutput?.isHighResolutionCaptureEnabled = true
                    
                    // Set the output on the capture session
                    captureSession?.addOutput(capturePhotoOutput!)
                    
                    // Initialize a AVCaptureMetadataOutput object and set it as the input device
                    let captureMetadataOutput = AVCaptureMetadataOutput()
                    captureSession?.addOutput(captureMetadataOutput)

                    // Set delegate and use the default dispatch queue to execute the call back
                    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                    
                    //Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                    videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    videoPreviewLayer?.frame = view.layer.bounds
                    previewView.layer.addSublayer(videoPreviewLayer!)
                    
                    //start video capture
                    captureSession?.startRunning()
                    
                    messageLabel.isHidden = true
                    
                    //Initialize QR Code Frame to highlight the QR code
                    qrCodeFrameView = UIView()
                    
                    if let qrCodeFrameView = qrCodeFrameView {
                        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                        qrCodeFrameView.layer.borderWidth = 2
                        view.addSubview(qrCodeFrameView)
                        view.bringSubviewToFront(qrCodeFrameView)
                    }
                } catch {
                    //If any error occurs, simply print it out
                    print(error)
                    return
                }
            
            }

        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }

        @IBAction func onTapTakePhoto(_ sender: Any) {
            // Make sure capturePhotoOutput is valid
            guard let capturePhotoOutput = self.capturePhotoOutput else { return }
            
            // Get an instance of AVCapturePhotoSettings class
            let photoSettings = AVCapturePhotoSettings()
            
            // Set photo settings for our need
           
            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.flashMode = .auto
            
            // Call capturePhoto method by passing our photo settings and a delegate implementing AVCapturePhotoCaptureDelegate
            capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }



    extension RecordViewController : AVCaptureMetadataOutputObjectsDelegate {
        func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                           didOutput metadataObjects: [AVMetadataObject],
                           from connection: AVCaptureConnection) {
            // Check if the metadataObjects array is contains at least one object.
            if metadataObjects.count == 0 {
                qrCodeFrameView?.frame = CGRect.zero
                messageLabel.isHidden = true
                return
            }
            
            // Get the metadata object.
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObject.ObjectType.qr {
                // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
                qrCodeFrameView?.frame = barCodeObject!.bounds
                
                if metadataObj.stringValue != nil {
                    messageLabel.isHidden = false
                    messageLabel.text = metadataObj.stringValue
                }
            }
        }
    }

    extension UIInterfaceOrientation {
        var videoOrientation: AVCaptureVideoOrientation? {
            switch self {
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeRight: return .landscapeRight
            case .landscapeLeft: return .landscapeLeft
            case .portrait: return .portrait
            default: return nil
            }
        }
    }


