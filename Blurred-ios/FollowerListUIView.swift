//
//  FollowerListUIView.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/6/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import SwiftUI
import SwiftKeychainWrapper
import Combine
import Foundation


struct Root: Codable {
    let followers: [Followers]
}
struct Followers: Codable {
    let followers: String
    let followerList: FollowerList
}
struct FollowerList: Codable {
    let username: String
}

class NetworkManager {
    var willChange = PassthroughSubject<NetworkManager, Never>()
    
    var root = Root.self {
        didSet {
            willChange.send(self)
        }
    }
    var followers = Followers.self {
        didSet {
            willChange.send(self)
        }
    }
    var followes = [FollowerList]() {
        didSet {
            willChange.send(self)
        }
    }
    init() {
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        guard let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data else { return }
            let followes = try! JSONDecoder().decode([FollowerList].self, from: data)
            DispatchQueue.main.async {
                self.followes = followes
            }
            print(followes)
            print("Completed fetching json")
        }.resume()
    }
}



struct FollowerListUIView : View {
       @State var networkManager = NetworkManager()
       var body: some View {
           NavigationView {
            List (
                networkManager.followes, id: \.username
            ) {
                Text($0.username)
            }.navigationBarTitle(Text("username"))
        }
    }
}

