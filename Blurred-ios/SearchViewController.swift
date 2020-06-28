//
//  SecondViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UICollectionViewDataSource, UISearchBarDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    }
    
    func textFieldShouldReturn(_ textField: UISearchBar) -> Bool {
        searchBarTextField.resignFirstResponder()
        return true
    }
    // Communicates with the api for search results
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBarTextField?.delegate? = self
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBarTextField: UISearchBar!
    

}

