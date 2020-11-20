//
//  CommentCellDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 10/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol CommentCellDelegate {
    func likeButtonTapped(commentId: Int, indexPath: IndexPath, reply: Bool)
    func readMoreButtonTapped(commentId: Int, indexPath: IndexPath)
    func moreButtonTapped(commentId: Int, indexPath: IndexPath, reply: Bool)
    func cellAvatarTapped(commentId: Int, indexPath: IndexPath, reply: Bool, name: String, isReported: Bool, avatarUrl: String)
}
