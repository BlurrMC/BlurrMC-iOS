//
//  OTPBackupCodesViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/14/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit

class OTPBackupCodesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var backupCodes = [String]()
    var otpSecret = String()
    var password = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }
    @IBAction func nextButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "showBackupCodes", sender: self)
    }
    
    // MARK: Pass data through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case is OTPViewController:
            let vc = segue.destination as? OTPBackupCodesViewController
            if segue.identifier == "showBackupCodes" {
                vc?.otpSecret = otpSecret
                vc?.password = password
            }
        default:
            break
        }
    }
    

}
extension OTPBackupCodesViewController: UITableViewDataSource {
    
    
    // MARK: Number Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backupCodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BackupCodeTableViewCell") as? BackupCodeTableViewCell else { return UITableViewCell() }
        cell.backupCode.text = self.backupCodes[indexPath.row]
        return cell
    }
    
    
}
