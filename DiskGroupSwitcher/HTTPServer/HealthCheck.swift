//
//  HealthCheck.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation

public struct HealthCheck : Codable {
    
    var application = ""
    var version = ""
    var timestamp = Date().timeIntervalSince1970
    var time = ""
    
    public init() {
        let appInfo = AppInfo()
        self.application = appInfo.appName
        self.version = appInfo.version
        let dt = DateFormatter()
        dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        self.time = dt.string(from: Date())
    }
    
    
    public func toJSON() -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json!
        }catch{
//            print(error)
            return "{}"
        }
    }
    
    public static func fromJSON(_ jsonString:String) -> HealthCheck? {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return nil}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(HealthCheck.self, from: jsonString.data(using: .utf8)!)
        }catch{
//            print(error)
            return nil
        }
    }
}

struct AppInfo {

   /// Returns the official app name, defined in your project data.
   var appName : String {
       return readFromInfoPlist(withKey: "CFBundleName") ?? "(unknown app name)"
   }

   /// Return the official app display name, eventually defined in your 'infoplist'.
   var displayName : String {
       return readFromInfoPlist(withKey: "CFBundleDisplayName") ?? "(unknown app display name)"
   }

   /// Returns the official version, defined in your project data.
   var version : String {
       return readFromInfoPlist(withKey: "CFBundleShortVersionString") ?? "(unknown app version)"
   }

   /// Returns the official 'build', defined in your project data.
   var build : String {
       return readFromInfoPlist(withKey: "CFBundleVersion") ?? "(unknown build number)"
   }

   /// Returns the minimum OS version defined in your project data.
   var minimumOSVersion : String {
    return readFromInfoPlist(withKey: "MinimumOSVersion") ?? "(unknown minimum OSVersion)"
   }

   /// Returns the copyright notice eventually defined in your project data.
   var copyrightNotice : String {
       return readFromInfoPlist(withKey: "NSHumanReadableCopyright") ?? "(unknown copyright notice)"
   }

   /// Returns the official bundle identifier defined in your project data.
   var bundleIdentifier : String {
       return readFromInfoPlist(withKey: "CFBundleIdentifier") ?? "(unknown bundle identifier)"
   }

   // MARK: - Private stuff

   // lets hold a reference to the Info.plist of the app as Dictionary
   private let infoPlistDictionary = Bundle.main.infoDictionary

   /// Retrieves and returns associated values (of Type String) from info.Plist of the app.
   private func readFromInfoPlist(withKey key: String) -> String? {
    return infoPlistDictionary?[key] as? String
   }
}
