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

    
    // MARK: Clear Cache
    @IBAction func clearCache(_ sender: Any) {
        clearAllCache()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: Clear the cache
    func clearAllCache() {
        removeNetworkDictionaryCache()
        ImageCache.shared.removeAll()
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        clearUrlCache()
    }
    
    
    // MARK: Clear the url shared cache
    func clearUrlCache() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Remove the network cache
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
    
    
    // MARK: Signout the user
    @IBAction func signOutButtonPressed(_ sender: Any) {
        let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
        let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
        try? myValet.removeObject(forKey: "Id")
        try? tokenValet.removeObject(forKey: "Token")
        try? myValet.removeAllObjects()
        try? tokenValet.removeAllObjects()
        self.removeFilePath(forKey: "Avatar")
        if #available(iOS 13.0, *) {
            let signInPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
            let appDelegate = UIApplication.shared.delegate
            appDelegate?.window??.rootViewController = signInPage
        } else {
            let homePage = AuthenticateViewController()
            self.present(homePage, animated:true, completion:nil)
        }
        
    }
    
    
    // MARK: File Path For Avatar
    private func removeFilePath(forKey key: String) {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return }
        do {
            try fileManager.removeItem(at: documentURL.appendingPathComponent(key + ".png"))
        } catch {
            print("error code: 0cjs943, error: \(error)")
        }
        
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true 
    }
    
    
    // MARK: Settings Back Button
    @IBAction func settingsBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
