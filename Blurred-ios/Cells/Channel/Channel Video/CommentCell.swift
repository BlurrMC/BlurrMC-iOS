//
//  CommentCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 7/12/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    
    var delegate: CommentCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.likeButtonTap(sender:)))
        likeButton.addGestureRecognizer(tap)
    }
    
    var commentId = Int()
    var indexPath = IndexPath()
    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var commentUsername: UILabel!
    @IBOutlet weak var commentAvatar: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // MARK: Like Button Tapped
    @objc func likeButtonTap(sender:UITapGestureRecognizer) {
        delegate?.likeButtonTapped(commentId: commentId, indexPath: indexPath)
    }

}
protocol CommentCellDelegate {
    func likeButtonTapped(commentId: Int, indexPath: IndexPath)
}
