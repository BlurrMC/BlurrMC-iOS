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

var array = [[String:Any]]()
struct Root: Codable {
    let followers = (array[0]["followers"] as! [String])[0] // Fucking kill me
}
@available(iOS 13.0, *)
class NetworkManager {
    var willChange = PassthroughSubject<NetworkManager, Never>()
    
    var root:Root {
        didSet {
            willChange.send(self)
        }
    }
    var rot = [Root]() {
        didSet {
            willChange.send(self)
        }
    }
    var followers = [Root]() {
        didSet {
            willChange.send(self)
        }
    }
    init() {
        let userId: Int?  = KeychainWrapper.standard.integer(forKey: "userId")
        guard let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(userId!).json") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data else { return }
            let root = try! JSONDecoder().decode(Root.self, from: data)
            DispatchQueue.main.async {
                self.root = root
            }
            print(root)
            print("Completed fetching json")
        }.resume()
    }
}



struct FollowerListUIView : View {
       @State var networkManager = NetworkManager()
       var body: some View {
           NavigationView {
            List (
                $networkManager.followers, id: \.followers
            ) {
                Text($0.followers)
            }.navigationBarTitle(Text("username"))
        }
    }
}

