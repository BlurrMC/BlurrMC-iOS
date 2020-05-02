//
//  ChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ChannelViewController: UIViewController { // Look at youself. Look at what you have done.

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    // func loadMemberChannel() {
    //     let accessToken: String? = KeychainWrapper.standard.string(forKey: "accessToken")
    //     let userId: String? = KeychainWrapper.standard.string(forKey: "userId")
    //     let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/cs/\(userId!)")
    //     var request = URLRequest(url:myUrl!)  // Setup the rest after devise api is done
    // } I will set this up later.

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
