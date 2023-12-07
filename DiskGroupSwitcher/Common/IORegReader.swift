//
//  IORegReader.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/12/7.
//

import Foundation
import LoggerFactory

public class IORegReader {
    let logger = LoggerFactory.get(category: "IOReg")
    
    static let `get` = IORegReader()
    
    private init() {}
    
    
    func read() {
        let pipe = Pipe()
        let command = Process()
        command.standardOutput = pipe
        command.standardError = pipe
        //            command.currentDirectoryURL = URL(fileURLWithPath: "/Users/kelvinwong/Documents")
        command.launchPath = "/bin/bash"
        command.arguments = ["--login", "-c", "ioreg -c IONVMeController"]
        do {
            self.logger.log(.trace, command.arguments![2])
            try command.run()
        }catch{
            self.logger.log(.error, error)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let response = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        let lines = response.components(separatedBy: "\n")
        for line in lines {
            
        }
    }
}
