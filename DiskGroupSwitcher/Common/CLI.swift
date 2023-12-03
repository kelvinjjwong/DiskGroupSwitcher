//
//  CliClick.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation
import LoggerFactory

struct CLI {
    
    let logger = LoggerFactory.get(category: "CommandLine")
    
    private init() {}
    
    static let `get` = CLI()
    
    func turnOn(siriComponent:String) {
        var key = Defaults.get.siriKey()
        if key == "option"{
            key = "alt"
        }
        if key == "control"{
            key = "ctrl"
        }
        if key == "command"{
            key = "cmd"
        }
        
        self.logger.log("turning on: \(siriComponent)")
            let pipe = Pipe()
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
//            command.currentDirectoryURL = URL(fileURLWithPath: "/Users/kelvinwong/Documents")
            command.launchPath = "/bin/bash"
            command.arguments = ["--login", "-c", "macism com.apple.keylayout.ABC; cliclick kd:fn kp:f11 ku:fn kd:\(key) kp:space ku:\(key) w:250 t:\"turn on \(siriComponent)\" kp:return kd:fn kp:f11 ku:fn"]
            do {
                self.logger.log(.trace, command.arguments![1])
                try command.run()
                self.logger.log("done")
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
//            if string != "" {
//                self.logger.log(string)
//            }
    }
    
    func turnOff(siriComponent:String) {
        var key = Defaults.get.siriKey()
        if key == "option"{
            key = "alt"
        }
        if key == "control"{
            key = "ctrl"
        }
        if key == "command"{
            key = "cmd"
        }
        self.logger.log("turning off: \(siriComponent)")
            let pipe = Pipe()
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryURL = URL(fileURLWithPath: "/Users")
            command.launchPath = "/bin/bash"
            command.arguments = ["--login", "-c", "macism com.apple.keylayout.ABC; cliclick kd:fn kp:f11 ku:fn kd:\(key) kp:space ku:\(key) w:250 t:\"shut down \(siriComponent)\" kp:return kd:fn kp:f11 ku:fn"]
            do {
                self.logger.log(.trace, command.arguments![1])
                try command.run()
                self.logger.log("done")
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
            if string != "" {
                self.logger.log(string)
            }
    }
    
    func query(siriComponent:String) {
        var key = Defaults.get.siriKey()
        if key == "option"{
            key = "alt"
        }
        if key == "control"{
            key = "ctrl"
        }
        if key == "command"{
            key = "cmd"
        }
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = "/bin/bash"
            command.arguments = ["--login", "-c", "macism com.apple.keylayout.ABC; cliclick kd:fn kp:f11 ku:fn kd:\(key) kp:space ku:\(key) w:250 t:\"is \(siriComponent) on?\" kp:return kd:fn kp:f11 ku:fn"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
//            if string != "" {
//                self.logger.log(string)
//            }
        }
    }
    
    func umount(volumes:[String]) -> [String] {
        var rtn:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = "/bin/bash"
            command.arguments = ["--login", "-c", "for v in \(volumes.joined(separator: " ")); do diskutil umount force $v; done"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
            if string != "" {
//                self.logger.log(string)
                rtn = string.components(separatedBy: "\n")
            }
        }
        return rtn
    }
    
    func listmount(volumes:[String]) -> [String] {
        var rtn:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = "/bin/bash"
            command.arguments = ["--login", "-c", "mount | grep \"local,\" | grep -v \"nobrowse\" | grep -v \"read-only\" | egrep \"\(volumes.joined(separator: "|"))\""]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
            if string != "" {
//                self.logger.log(string)
                rtn = string.components(separatedBy: "\n")
            }
        }
        return rtn
    }
    
}
