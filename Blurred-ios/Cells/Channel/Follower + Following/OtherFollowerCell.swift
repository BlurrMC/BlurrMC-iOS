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
    }

    // MARK: Variables and properties
    var name = String()
    var isReported = Bool()
    var avatarUrl = String()
    @IBOutlet weak var followerUsername: UILabel!
    @IBOutlet weak var followerName: UILabel!
    @IBOutlet weak var followerAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        followerAvatar.image = nil
        isHidden = false
        isSelected = false
        isHighlighted = false
    }

}
