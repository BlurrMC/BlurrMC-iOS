//
//  NotificationsTableViewCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 9/15/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class NotificationsTableViewCell: UITableViewCell {

    @IBOutlet weak var unreadBubble: UIImageView!
    @IBOutlet weak var notificationDescription: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.thumbnailView.contentScaleFactor = 1.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
