//
//  Settings.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Foundation

public class Settings {
    
    static let `stored` = Settings()
    
    private init() {}
    
    
    func servers() -> [String] {
        var list:[String] = []
        let defaults = UserDefaults.standard
        let txt = defaults.string(forKey: "SERVERS") ?? ""
        
        for t in txt.components(separatedBy: ",") {
            list.append(t)
        }
        return list
    }
    
    func volumes() -> [String] {
        var list:[String] = []
        let defaults = UserDefaults.standard
        let txt = defaults.string(forKey: "VOLUMES") ?? ""
        
        for t in txt.components(separatedBy: ",") {
            list.append(t)
        }
        return list
    }
}
