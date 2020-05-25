//
//  UploadDetailsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/25/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class UploadDetailsViewController: UIViewController {
    
    var videoDetails = String()
    @IBAction func doneButton(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        uploadRequest()
    }
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var descriptionField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    func uploadRequest() {
        // Move the upload request from the videoplaybackviewcontroller to here.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
