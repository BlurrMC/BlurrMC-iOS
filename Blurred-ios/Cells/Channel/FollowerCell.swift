//
//  Follower.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/9/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class FollowerCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBOutlet weak var followerAvatar: UIImageView!
    @IBOutlet weak var followerName: UILabel!
    @IBOutlet weak var followerUsername: UILabel!
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
