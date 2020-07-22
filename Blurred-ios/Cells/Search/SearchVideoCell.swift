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
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBOutlet weak var searchDate: UILabel!
    @IBOutlet weak var searchViewCount: UILabel!
    @IBOutlet weak var searchUsername: UILabel!
    @IBOutlet weak var searchDescription: UILabel!
    @IBOutlet weak var searchThumbnail: UIImageView!

}
