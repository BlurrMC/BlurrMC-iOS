//
//  CommentCellDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 10/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

protocol CommentCellDelegate {
    func likeButtonTapped(commentId: String, indexPath: IndexPath, reply: Bool)
    func readMoreButtonTapped(commentId: String, indexPath: IndexPath)
    func moreButtonTapped(commentId: String, indexPath: IndexPath, reply: Bool)
    func cellAvatarTapped(commentId: String, indexPath: IndexPath, reply: Bool, name: String, isReported: Bool, avatarUrl: String)
}
