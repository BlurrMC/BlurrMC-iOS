//
//  SettingsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke

class SettingsViewController: UIViewController {

    @IBAction func clearCache(_ sender: Any) {
        removeNetworkDictionaryCache()
        ImageCache.shared.removeAll()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    func removeNetworkDictionaryCache() {
        let caches = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
        let appId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        let path = String(format:"%@/%@/Cache.db-wal",caches, appId)
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("ERROR DESCRIPTION: \(error)")
        }
    }
    @IBAction func signOutButtonPressed(_ sender: Any) {
        let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
        let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
        try? myValet.removeObject(forKey: "Id")
        try? tokenValet.removeObject(forKey: "Token")
        try? myValet.removeAllObjects()
        try? tokenValet.removeAllObjects()
        if #available(iOS 13.0, *) {
            let signInPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
            let appDelegate = UIApplication.shared.delegate
            appDelegate?.window??.rootViewController = signInPage
        } else {
            let homePage = AuthenticateViewController()
            self.present(homePage, animated:true, completion:nil)
        }
        
    }
      
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // Again with the tab barss.

        // Do any additional setup after loading the view.
        // I did not hit her!
    }
    @IBAction func settingsBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
