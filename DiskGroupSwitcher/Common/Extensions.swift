//
//  Extensions.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Cocoa


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
    
    func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        guard let range = self.range(of: string) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
    
    func getVolumeFromThisPath() -> (String, String) {
        if self.hasPrefix("/Volumes/") {
            let parts = self.components(separatedBy: "/")
            let volume = "/\(parts[1])/\(parts[2])"
            let _path = self.replacingFirstOccurrence(of: volume, with: "")
            return (volume, _path)
        }else{
            return ("", self)
        }
    }
    
    func getSoftlinkTargetFromThisPath() -> String {
        return LocalDirectory.bridge.getSoftlink(path: self)
    }
    
    func unlink() {
        LocalDirectory.bridge.unlink(softlink: self)
    }
    
    func link(to target:String) {
        LocalDirectory.bridge.link(softlink: self, target: target)
    }
    
    func isVolumeExists() -> Bool {
        let (volume, _) = self.getVolumeFromThisPath()
        let mountedVolumes = LocalDirectory.bridge.listMountedVolumes()
        
        return mountedVolumes.contains(volume)
    }
    
    func isDirectoryExists() -> Bool {
        var isDir:ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDir) {
            if isDir.boolValue == true {
                return true
            }
        }
        return false
    }
    
    func isFileExists() -> Bool {
        if FileManager.default.fileExists(atPath: self) {
            return true
        }
        return false
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
        return self.getString(key: key, defaultValue: defaultValue)
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


extension NSColor {
    
    convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: CGFloat(1)
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
    }

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
