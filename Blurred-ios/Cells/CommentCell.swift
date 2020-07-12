//
//  CommentCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 7/12/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var commentUsername: UILabel!
    @IBOutlet weak var commentAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
