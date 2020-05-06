//
//  FollowerListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/4/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftKeychainWrapper
import Alamofire
import Combine

struct Root: Codable {
    let followers : FollowerData
}
struct FollowerData: Codable {
    enum CodingKeys: String, CodingKey {
        case username = "username"
    }
    let username: String
}

@available(iOS 13.0, *)
class NetworkManager {
    var didChange = PassthroughSubject<NetworkManager, Never>()
    
    var followers = [FollowerData]() {
        didSet {
            didChange.send(self)
        }
    }
    
    init() {
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        guard let url = URL(string: "http://10.0.0.2:3000/api/v1/channels\(userId!).json") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data else { return }
            let followers = try! JSONDecoder().decode([FollowerData].self, from: data)
            DispatchQueue.main.async {
                self.followers = followers
            }
            print("Completed fetching json")
        }.resume()
    }
}



struct ContentView : View {
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

