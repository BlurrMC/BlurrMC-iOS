//
//  SecondViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate {
    
    // Fill it up
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBarTextField?.delegate? = self
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var searchBarTextField: UISearchBar!
    

}

