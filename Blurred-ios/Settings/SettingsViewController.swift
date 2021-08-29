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
import Alamofire

class SettingsViewController: UIViewController {
    
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    
    // MARK: Clear Cache
    @IBAction func clearCache(_ sender: Any) {
        clearAllCache()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func tapped2FASettings(_ sender: Any) {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/checkforotp", method: .post, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let status = JSON?["status"] as? String else {
                    self.showMessage(title: "Error", message: "Unknown alert has occured. Try again later.", alertActionTitle: "OK", cancelAction: false, secondAlertActionTitle: nil)
                    return
                }
                if status == "OTP required" {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "disableOTP", sender: self)
                    }
                } else if status == "OTP not required" {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "EnableOTP", sender: self)
                    }
                }
            } catch {
                print("error code: asdf98uiqnjaksd")
            }
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
    
    // MARK: Remove all objects for user
    func removeObjectsFromUser() {
        let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
        try? myValet.removeObject(forKey: "Id") 
        try? tokenValet.removeObject(forKey: "Token")
        try? tokenValet.removeObject(forKey: "NotificationToken")
        try? myValet.removeAllObjects()
        try? tokenValet.removeAllObjects()
        self.removeFilePath(forKey: "Avatar")
        removeNotificationTokenFromBackend()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNMutableNotificationContent().badge = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
        let signInPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = signInPage
    }
    
    
    // MARK: Signout the user
    @IBAction func signOutButtonPressed(_ sender: Any) {
        let networkStatus = Reachability().connectionStatus()
        switch networkStatus {
        case .Unknown, .Offline :
            showMessage(title: "Alert", message: "Signing out without an internet connection is not recommended. Are you sure???", alertActionTitle: "I'll go back...", cancelAction: true, secondAlertActionTitle: "Sign out")
        case .Online(_):
            removeObjectsFromUser()
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
    
    
    // MARK: Removes the notification token from backend
    func removeNotificationTokenFromBackend() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/notificationtokenremoval", method: .get, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: asfd9j1diasjck")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    guard let status: String = parseJSON["status"] as? String else { return }
                    if status != "Successfully cleared notification token" {
                        print("notification token could not be removed, error code: asdf9j1edssadcaz, status: \(status)")
                    }
                }
            } catch {
                print("error code: f1e1212313123123, error: \(error)")
                return
            }
        }

    }
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String, cancelAction: Bool, secondAlertActionTitle: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        switch cancelAction {
        case true:
            alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: secondAlertActionTitle, style: UIAlertAction.Style.destructive, handler: {_ in
                self.removeObjectsFromUser()
            }))
        case false:
            alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
