//
//  OtherFollowerCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class OtherFollowerCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    // Yes I know it is stupid to have four view controllers for having the same two lists.

    @IBOutlet weak var followerUsername: UILabel!
    @IBOutlet weak var followerName: UILabel!
    @IBOutlet weak var followerAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        followerAvatar.image = nil
        isHidden = false
        isSelected = false
        isHighlighted = false
    }

}
