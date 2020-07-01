//
//  FollowingCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/10/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class FollowingCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var followingUsername: UILabel!
    @IBOutlet weak var followingName: UILabel!
    @IBOutlet weak var followingAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        followingAvatar.image = nil
        isHidden = false
        isSelected = false
        isHighlighted = false
    }

}
