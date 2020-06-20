//
//  AppDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import CoreData
import Valet
import AVFoundation

@available(iOS 13.0, *) // Again, ios 13?
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    func applicationDidBecomeActive(_ application: UIApplication) {

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            print("AVAudioSessionCategoryPlayback not work")
        }
    }
    // MARK: - Core Data stack

    @available(iOS 13.0, *)
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "Blurred_ios")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    public var isItLoading: Bool = false
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let accessToken: String? = tokenValet.string(forKey: "Token")
        let userId: String? = myValet.string(forKey: "Id")
        if accessToken != nil && userId != nil {
            sleep(2);
            isItLoading = true
            let Id = Int(userId!)
                let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/isuservalid/\(Id!).json")
                var request = URLRequest(url:myUrl!)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "content-type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                    if error != nil {
                        print("there is an error")
                        return
                    }
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                        if let parseJSON = json {
                            let status: String? = parseJSON["status"] as? String
                            if status == "User is valid! YAY :)" {
                                DispatchQueue.main.async {
                                    let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    let homePage = storyboard.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
                                    self.window?.rootViewController = homePage
                                    self.window?.makeKeyAndVisible()
                                    self.isItLoading = false
                                }
                            } else if status == "User is not valid. Oh no!" {
                                self.myValet.removeObject(forKey: "Id")
                                self.tokenValet.removeObject(forKey: "Token")
                                self.isItLoading = false
                                return
                            } else {
                                return
                            }
                        } else {
                            print("else")
                            return
                        }
                    } catch {
                        print("catch")
                        return
                    }
                }
            isItLoading = false
            task.resume()
            }
        return true
        }
}

