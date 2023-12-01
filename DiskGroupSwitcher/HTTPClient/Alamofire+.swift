//
//  Alamofire+.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/12/1.
//

import Foundation
import Alamofire

extension String {
    
    func post(url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = self.data()
        return request
    }
}
