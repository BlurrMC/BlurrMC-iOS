//
//  EULAViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/29/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Alamofire

// NOTE: This controller should only be shown to the user once.
class EULAViewController: UIViewController {
    
    var alreadySeen: Bool = false
    
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
        if alreadySeen != true {
            DispatchQueue.main.async {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return } /// Now it's 11:11 but only 8 in LA
                self.present(nextViewController, animated: true, completion: nil)
            }
        } else {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    // MARK: User disagreed
    @IBAction func disagreeButtonTap(_ sender: Any) {
        if self.alreadySeen != true {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
        try? self.myValet.setString("false", forKey: "EULAAgreed")
        try? myValet.removeObject(forKey: "Id")
        try? tokenValet.removeObject(forKey: "Token")
        try? tokenValet.removeObject(forKey: "NotificationToken")
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
    
    // MARK: Removes the notification token from backend
    func removeNotificationTokenFromBackend() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("https://blurrmc.com/api/v1/notificationtokenremoval", method: .get, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: a0990i09a98347239841")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    guard let status: String = parseJSON["status"] as? String else { return }
                    if status != "Successfully cleared notification token" {
                        print("notification token could not be removed, error code: mas8f7msdf67dstf7as6dftasdufqewa, status: \(status)")
                    }
                }
            } catch {
                print("error code: asdf9ir8fahiusd3, error: \(error)")
                return
            }
        }

    }
    
    // MARK: Remove avatar file
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
}
