//
//  HTTPResponse.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation

struct HTTPResponse : Decodable{
    var mounted:Bool
    var volume:String
    var error:String?
    
    public static func fromJSON(_ jsonString:String) -> HTTPResponse? {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return nil}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(HTTPResponse.self, from: jsonString.data(using: .utf8)!)
        }catch{
            //print(error)
            return nil
        }
    }
}
