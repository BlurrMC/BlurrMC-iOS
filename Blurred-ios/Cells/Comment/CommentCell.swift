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
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.likeButtonTap(sender:)))
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(self.moreButtonTap(sender:)))
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.avatarTap(sender:)))
        likeButton.addGestureRecognizer(tap)
        moreButton.addGestureRecognizer(moreTap)
        commentAvatar.addGestureRecognizer(avatarTap)
        self.commentAvatar.layer.cornerRadius = self.commentAvatar.bounds.height / 2
    }
    
    var delegate: CommentCellDelegate?
    var commentId = String()
    var indexPath = IndexPath()
    var commentName = String()
    var reported = Bool()
    var avatarUrl = String()
    @IBOutlet weak var moreButton: UIImageView!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var commentUsername: UILabel!
    @IBOutlet weak var commentAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // MARK: Avatar Button Tap Recognizer
    @objc func avatarTap(sender:UITapGestureRecognizer) {
        delegate?.cellAvatarTapped(commentId: commentId, indexPath: indexPath, reply: false, name: commentName, isReported: reported, avatarUrl: avatarUrl)
    }
    
    
    // MARK: More Button Tap Recognizer
    @objc func moreButtonTap(sender:UITapGestureRecognizer) {
        delegate?.moreButtonTapped(commentId: commentId, indexPath: indexPath, reply: false)
    }
    
    
    // MARK: Read More Button Tapped
    @IBAction func readMore(_ sender: Any) {
        delegate?.readMoreButtonTapped(commentId: commentId, indexPath: indexPath)
    }
    
    // MARK: Like Button Tap Recognizer
    @objc func likeButtonTap(sender:UITapGestureRecognizer) {
        delegate?.likeButtonTapped(commentId: commentId, indexPath: indexPath, reply: false)
    }

}
