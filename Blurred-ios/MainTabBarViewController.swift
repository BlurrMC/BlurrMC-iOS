//
//  MainTabBarViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 11/20/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import AlamofireImage

class MainTabBarViewController: UITabBarController {
    
    @IBOutlet weak var mainTabBar: UITabBar!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = self.retrieveImage(forKey: "Avatar") {
            let preImage = image.resize(targetSize: CGSize(width: 30, height: 30))
            let postImage = preImage.af.imageRounded(withCornerRadius: 15)
            
            self.viewControllers?[4].tabBarItem.image = postImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        }
        // self.viewControllers?[3].tabBarItem.badgeValue = "3"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(tapFromNotification(_:)), name: .notificationtap, object: "notificationtap")
    }
    
    @objc func tapFromNotification(_ notification: Notification) {
        self.selectedIndex = 3
    }
    
    // MARK: Load avatar for tab bar
    private func retrieveImage(forKey key: String) -> UIImage? {
        if let filePath = self.filePath(forKey: key),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData) {
            return image
        }
        print("error code: 0fmviq940ckc9rka93d")
        return nil
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        return documentURL.appendingPathComponent(key + ".png")
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
extension UIImage {

    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

}
