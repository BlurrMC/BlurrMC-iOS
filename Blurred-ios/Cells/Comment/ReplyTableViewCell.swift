//
//  ReplyTableViewCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 10/25/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class ReplyTableViewCell: UITableViewCell {
    
    // MARK: Variables and Properties
    var commentId = Int()
    var indexPath = IndexPath()
    var parentId = Int()
    var delegate: CommentCellDelegate?
    var name = String()
    var isReported = Bool()
    var avatarUrl = String()
    @IBOutlet weak var moreButton: UIImageView!
    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(self.moreButtonTap(sender:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.likeButtonTap(sender:)))
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.avatarTap(sender:)))
        likeButton.addGestureRecognizer(tap)
        moreButton.addGestureRecognizer(moreTap)
        avatar.addGestureRecognizer(avatarTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // MARK: Avatar Button Tap Recognizer
    @objc func avatarTap(sender:UITapGestureRecognizer) {
        delegate?.cellAvatarTapped(commentId: commentId, indexPath: indexPath, reply: true, name: name, isReported: isReported, avatarUrl: avatarUrl)
    }
    
    
    // MARK: More Button Tap Recognizer
    @objc func moreButtonTap(sender:UITapGestureRecognizer) {
        delegate?.moreButtonTapped(commentId: commentId, indexPath: indexPath, reply: true)
    }
    
    
    // MARK: Like Button Tapped
    @objc func likeButtonTap(sender:UITapGestureRecognizer) {
        delegate?.likeButtonTapped(commentId: commentId, indexPath: indexPath, reply: true)
    }

}
