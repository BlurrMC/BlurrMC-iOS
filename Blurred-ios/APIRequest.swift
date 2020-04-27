//
//  APIRequest.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/27/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation

enum APIError:Error {
    case ResponseProblem
    case DecodingProblem
    case OtherProblem
}
struct APIRequest {
    let resourceURL: URL
    
    init(endpoint: String) {
        let resourceString = "http://10.0.0.2:3000/api/v1\(endpoint)"
        guard let resourceURL = URL(string: resourceString) else {fatalError()}
        // Once the local ip has been change, change arbitrary loads to NO in info.plist
        
        self.resourceURL = resourceURL 
    }
}
