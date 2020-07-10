//
//  SearchVideoCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 7/1/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class SearchVideoCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        searchThumbnail.image = nil
        isHidden = false
        isSelected = false
        isHighlighted = false
    }
    @IBOutlet weak var searchByUsername: UILabel!
    @IBOutlet weak var searchTitle: UILabel!
    @IBOutlet weak var searchThumbnail: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
