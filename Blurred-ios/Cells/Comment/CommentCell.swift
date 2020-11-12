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
        likeButton.addGestureRecognizer(tap)
        moreButton.addGestureRecognizer(moreTap)
    }
    
    
    
    var delegate: CommentCellDelegate?
    var commentId = Int()
    var indexPath = IndexPath()
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
