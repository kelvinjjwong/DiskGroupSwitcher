//
//  Extensions.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Foundation


extension String {
    func toJSONArray() -> [JSON] {
        if let data = self.data(using: .utf8) {
            do {
                let json = try JSON(data: data)
                return json.array ?? []
            }catch{
                print(error)
            }
        }
        return []
    }
}

extension Array {
    func toJSONString() -> String {
        let json = JSON(self)
        let jsonString = json.rawString(.utf8, options: [.fragmentsAllowed, .withoutEscapingSlashes]) ?? "[]"
        return jsonString
    }
    
    func appending<S>(_ newElements: S) -> [Element] where Element == S.Element, S : Sequence  {
        var arr = self
        arr.append(contentsOf: newElements)
        return arr
    }
}


extension UserDefaults {
    
    func get(key:String) -> String {
        return self.getString(key: key, defaultValue: "")
    }
    
    func get(key:String, defaultValue:String) -> String {
        return self.getString(key: key, defaultValue: "")
    }
    
    func getString(key:String) -> String {
        return self.getString(key: key, defaultValue: "")
    }
    
    func getString(key:String, defaultValue:String) -> String {
        let defaults = UserDefaults.standard
        guard let txt = defaults.string(forKey: key) else {return defaultValue}
        if txt == "" {return defaultValue}
        return txt
    }
    
    func getInt(key:String) -> Int {
        return self.getInt(key: key, defaultValue: 0)
    }
    
    func getInt(key:String, defaultValue:Int) -> Int {
        let defaults = UserDefaults.standard
        guard let txt = defaults.string(forKey: key) else {return defaultValue}
        if let value = Int(txt) {
            return value
        }else{
            return defaultValue
        }
    }
    
    func getBool(key:String) -> Bool {
        return self.getBool(key: key, defaultValue: false)
    }
    
    func getBool(key:String, defaultValue:Bool) -> Bool {
        let defaults = UserDefaults.standard
        guard let txt = defaults.string(forKey: key) else {return defaultValue}
        if txt == "true"  {
            return true
        }else{
            return false
        }
    }
    
    func getJSON(key:String) -> JSON {
        let jsonString = self.getString(key: key)
        guard jsonString != "" else {return JSON(NSNull())}
        return JSON(parseJSON: jsonString)
    }
    
    func save(key:String, value:String) {
        self.saveString(key: key, value: value)
    }
    
    func saveString(key:String, value:String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey:key)
    }
    
    func saveInt(key:String, value:Int) {
        let defaults = UserDefaults.standard
        defaults.set("\(value)", forKey:key)
    }
    
    func saveBool(key:String, value:Bool) {
        let defaults = UserDefaults.standard
        defaults.set("\(value)", forKey:key)
    }
}
