//
//  OtherChannelVideoCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/30/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire

class OtherChannelVideoCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = UIImage(named: "load-image")
        isHidden = false
        isSelected = false
        isHighlighted = false
    }
}
