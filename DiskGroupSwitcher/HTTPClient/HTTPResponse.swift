//
//  HTTPResponse.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation

struct MountedResponse : Decodable{
    var mounted:Bool
    var volume:String
    var error:String?
    
    public static func fromJSON(_ jsonString:String) -> MountedResponse? {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return nil}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(MountedResponse.self, from: jsonString.data(using: .utf8)!)
        }catch{
            //print(error)
            return nil
        }
    }
}

struct LinkedResponse : Decodable{
    var linked:Bool
    var volume:String
    var softlink:String
    
    public static func fromJSON(_ jsonString:String) -> LinkedResponse? {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return nil}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(LinkedResponse.self, from: jsonString.data(using: .utf8)!)
        }catch{
            //print(error)
            return nil
        }
    }
}

struct GenericResponse : Decodable{
    var status:Bool
    
    public static func fromJSON(_ jsonString:String) -> GenericResponse? {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return nil}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(GenericResponse.self, from: jsonString.data(using: .utf8)!)
        }catch{
            //print(error)
            return nil
        }
    }
}
