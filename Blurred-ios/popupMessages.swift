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
}
