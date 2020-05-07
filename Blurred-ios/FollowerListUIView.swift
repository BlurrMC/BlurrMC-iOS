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
    let username: String
}
@available(iOS 13.0, *)
class NetworkManager {
    var didChange = PassthroughSubject<NetworkManager, Never>()
    
    var followers = [Followers]() {
        didSet {
            didChange.send(self)
        }
    }
    var root = Root.self {
        didSet {
            didChange.send(self)
        }
    }
    
    init() {
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        guard let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data else { return }
            let root = try! JSONDecoder().decode(Root.self, from: data)
            DispatchQueue.main.async {
                root.followers
            }
            print("Completed fetching json")
        }.resume()
    }
}



struct FollowerListUIView : View {
       @State var networkManager = NetworkManager()
       var body: some View {
           NavigationView {
            List (
                networkManager.followers, id: \.username
            ) {
                Text($0.username)
            }.navigationBarTitle(Text("Followers"))
        }
    }
}

