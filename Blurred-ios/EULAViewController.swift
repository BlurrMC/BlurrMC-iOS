//
//  EULAViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/29/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Valet

// NOTE: This controller should only be shown to the user once.
class EULAViewController: UIViewController {
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    
    // MARK: View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "EULA"
    }
    
    // MARK: EULA tap (web)
    @IBAction func EULAButtonTap(_ sender: Any) {
        guard let eulaUrl = URL(string: "https://blurrmc.com/eula/") else { return }
        UIApplication.shared.open(eulaUrl)
    }
    
    // MARK: User agreed
    @IBAction func agreeButtonTap(_ sender: Any) {
        try? self.myValet.setString("true", forKey: "EULAAgreed")
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return } /// Now it's 11:11 but only 8 in LA
            self.present(nextViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: User disagreed
    @IBAction func disagreeButtonTap(_ sender: Any) {
        try? self.myValet.setString("false", forKey: "EULAAgreed")
        try? myValet.removeObject(forKey: "Id")
        try? tokenValet.removeObject(forKey: "Token")
        try? tokenValet.removeObject(forKey: "NotificationToken")
        try? tokenValet.removeAllObjects()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
