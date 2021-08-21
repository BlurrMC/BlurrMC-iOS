//
//  showMessage.swift
//  Blurred-ios
//
//  Created by Martin Velev on 6/4/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import Foundation
import UIKit

public class popupMessages {
    func showMessage(title: String, message: String, alertActionTitle: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func showMessageWithOptions(title: String, message: String, firstOptionTitle: String, secondOptionTitle: String, viewController: UIViewController, _ block: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: firstOptionTitle, style: .default, handler: {_ in 
            block()
        }))
        alert.addAction(UIAlertAction(title: secondOptionTitle, style: .cancel, handler: nil))
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
