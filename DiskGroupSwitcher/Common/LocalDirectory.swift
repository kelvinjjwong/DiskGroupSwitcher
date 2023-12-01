//
//  LocalDirectory.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation
import LoggerFactory

struct LocalDirectory {
    
    let logger = LoggerFactory.get(category: "LocalDirectory")
    
    static let bridge = LocalDirectory()
    
    func datetime(of filename: String, in path:String) -> String {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = path
            command.launchPath = "/usr/bin/stat"
            command.arguments = ["-l","-t","'%F %T'", filename]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        if string != "" {
            let columns = string.components(separatedBy: " ")
            if columns.count > 7 {
                let date = columns[5]
                let time = columns[6]
                let datetime = "\(date) \(time)"
                return datetime
            }
        }
        return ""
    }
    
    fileprivate func filenamesForReference(in path: String, recursive:Bool=false) -> [String:[String]] {
//        self.logger.log("getting folders from \(path)")
        var result:[String:[String]] = [:]
        let param = recursive ? "-1tR" : "-1"
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = path
            command.launchPath = "/bin/ls"
            command.arguments = [param]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        let lines = string.components(separatedBy: "\n")
        var subFolder = ""
        for line in lines {
            if line == "" {
                continue
            }
            if line.hasPrefix(".") && line.hasSuffix(":") {
                if line == ".:" {
                    subFolder = ""
                }else{
                    let indexStartOfText = line.index(line.startIndex, offsetBy: 2)
                    let indexEndOfText = line.index(line.endIndex, offsetBy: -1)
                    subFolder = String(line[indexStartOfText..<indexEndOfText])
                }
                continue
            }
            let folder = subFolder == "" ? "." : subFolder
            var filenames = result[folder]
            if filenames == nil {
                filenames = [line]
                result[folder] = filenames
            }else{
                filenames!.append(line)
                result[folder] = filenames
            }
        }
        return result
    }
    
    func occupiedDiskSpace(path: String) -> [String:String] {
//        self.logger.log("getting occupied disk space of \(path)")
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = path
            command.launchPath = "/usr/bin/du"
            command.arguments = ["-h", "."]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        var result:[String:String] = [:]
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line == "" {continue}
            //self.logger.log(line)
            var columns:[String] = []
            let cols = line.components(separatedBy: "\t")
            for col in cols {
                if col == "" || col == " " {
                    continue
                }
                //self.logger.log("col -> \(col)")
                columns.append(col)
            }
            let space = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let subpath = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            result[subpath] = space
            //self.logger.log("\(subpath) -> \(space)")
        }
        result["console_output"] = string
        return result
    }
    
    func mountpoints() -> [String] {
        var volumes:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = "/bin/df"
            command.arguments = ["-bH"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
            
            let lines = string.components(separatedBy: "\n")
            for line in lines {
                if line == "" || line.hasPrefix("Filesystem") {continue}
                let cols = line.components(separatedBy: " ")
                for col in cols {
                    if col == "" || col == " " {
                        continue
                    }
                    if col == "/" || col.starts(with: "/Volumes/") {
                        volumes.append(col)
                    }
                }
            }
        }
        return volumes
    }
    
    func getSoftlink(path:String) -> String {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = "/Users/"
            command.launchPath = "/bin/bash"
            command.arguments = ["-c", "ls -l \(path) | awk -F' ' '{print substr($0, index($0,$9))}'"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line == "" {continue}
            if line.contains(" -> ") {
                let parts = line.components(separatedBy: " -> ")
                return parts[1]
            }
        }
        return ""
    }
    
    func unlink(softlink:String) {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = "/Users/"
            command.launchPath = "/bin/bash"
            command.arguments = ["-c", "rm -f \"\(softlink)\""]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        _ = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
    }
    
    func link(softlink:String, target:String) {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = "/Users/"
            command.launchPath = "/bin/bash"
            command.arguments = ["-c", "ln -s \"\(target)\" \"\(softlink)\""]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        _ = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
    }
    
    func listMountedVolumes() -> [String] {
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = "/Volumes/"
            command.launchPath = "/bin/bash"
            command.arguments = ["-c", "ls -l /Volumes | grep \"drwxrwxr-x\" | awk -F' ' '{print substr($0, index($0,$9))}'"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        var result:[String] = []
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line == "" {continue}
            
            result.append("/Volumes/\(line)")
        }
        return result
    }
    
    func freeSpace(path: String) -> (String, String, String) {
//        self.logger.log("getting free space of \(path)")
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = path
            command.launchPath = "/bin/df"
            command.arguments = ["-bH", "."]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        var totalSize = ""
        var freeSize = ""
        var mountPoint = ""
        
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line == "" || line.hasPrefix("Filesystem") {continue}
//            self.logger.log(line)
            var columns:[String] = []
            let cols = line.components(separatedBy: " ")
            for col in cols {
                if col == "" || col == " " {
                    continue
                }
                //self.logger.log("col -> \(col)")
                columns.append(col)
            }
            if columns.count >= 6 {
                totalSize = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                freeSize = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                for i in 5...(columns.count-1) {
                    mountPoint += columns[i]
                    mountPoint += " "
                }
            }
        }
//        self.logger.log("\(mountPoint) -> \(freeSize) / \(totalSize)")
        return (totalSize, freeSize, mountPoint.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    public func getDiskMountPointVolume(path:String) -> String {
        var isDir:ObjCBool = false
        if path.trimmingCharacters(in: .whitespacesAndNewlines) != ""
            && FileManager.default.fileExists(atPath: path.trimmingCharacters(in: .whitespacesAndNewlines), isDirectory: &isDir)
            && isDir.boolValue == true {
            let (totalSize, freeSize, mountPoint) = self.freeSpace(path: path)
            self.logger.log(.trace, "get volume of path: \(path) - volume: \(mountPoint) - total:\(totalSize), free:\(freeSize)")
            return mountPoint
        }else{
            return ""
        }
    }
    
    public func getSymbolicLinkDestination(path:String) -> String {
        let url = URL(fileURLWithPath: path)
        if let ok = try? url.checkResourceIsReachable(), ok {
            let vals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
            if let islink = vals?.isSymbolicLink, islink {
                if let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
                    return dest
                }
            }
        }
        return path
    }
    
    public func getSizeInGB(size:String) -> Double{
        var sizeAmount = 0.0
        sizeAmount = Double(size.substring(from: 0, to: -1)) ?? 0
        if size.hasSuffix("T") {
            sizeAmount = sizeAmount * 1000 * 1000
        }
        if size.hasSuffix("G") {
            sizeAmount = sizeAmount * 1000
        }
        if size.hasSuffix("B") || size.hasSuffix("K") {
            sizeAmount = 0
        }
        let sizeGB:Double = sizeAmount / 1000
        return sizeGB
    }
    
}
