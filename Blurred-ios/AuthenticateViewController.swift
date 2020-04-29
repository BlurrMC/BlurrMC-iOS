//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController {
    
    @IBOutlet weak var EmailCredsField: UITextField!
    @IBOutlet weak var PasswordCredsField: UITextField!
    
    
    // Has to contact the devise api sending it's credentials to make sure it's good then it sends a token back

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        // Do any additional setup after loading the view.
        EmailCredsField.delegate = self
        PasswordCredsField.delegate = self
    }

    @IBAction func SubmitCreds(_ sender: UIButton) {
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
extension AuthenticateViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
