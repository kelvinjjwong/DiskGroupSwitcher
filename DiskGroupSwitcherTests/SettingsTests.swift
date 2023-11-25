//
//  SettingsTests.swift
//  DiskGroupSwitcherTests
//
//  Created by Kelvin Wong on 2023/11/25.
//

import XCTest
@testable import DiskGroupSwitcher

final class SettingsTests: XCTestCase {
    
    func testToJSON() {
        let server1 = Server(hostname: "kelvinstation.local",
                             ssd: DiskGroup(name: "Station Fast", disks: [
                                Disk(volume: "FastPhoto1"),
                                Disk(volume: "FastPhoto2"),
                                Disk(volume: "FastPhoto3")
                             ]),
                             hdd: DiskGroup(name: "Station HDD", disks: [
                                Disk(volume: "Photo1"),
                                Disk(volume: "Photo2"),
                                Disk(volume: "Photo3")
                             ]))
        
        
        let server2 = Server(hostname: "photostation.local",
                             ssd: DiskGroup(name: "Photo Fast", disks: [
                                Disk(volume: "ImageStorageFast")
                             ]),
                             hdd: DiskGroup(name: "Photo HDD", disks: [
                                Disk(volume: "ImageStorage")
                             ]))
        
        let servers:[Server] = [server1, server2]
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(servers)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            print(json!)
        }catch{
            print(error)
        }
            
            
    }
    
    func testFromJSON() {
        let jsonString = """
[{"hostname":"kelvinstation.local","hddGroup":{"disks":[{"online":false,"volume":"Photo1"},{"volumn":"Photo2","online":false},{"online":false,"volumn":"Photo3"}],"name":"Station HDD","selected":false},"online":false,"ssdGroup":{"selected":false,"name":"Station Fast","disks":[{"volumn":"FastPhoto1","online":false},{"volumn":"FastPhoto2","online":false},{"online":false,"volumn":"FastPhoto3"}]}},{"hostname":"photostation.local","ssdGroup":{"disks":[{"online":false,"volumn":"ImageStorageFast"}],"selected":false,"name":"Photo Fast"},"online":false,"hddGroup":{"name":"Photo HDD","selected":false,"disks":[{"online":false,"volumn":"ImageStorage"}]}}]
"""
        let jsonDecoder = JSONDecoder()
        do{
            let servers = try jsonDecoder.decode([Server].self, from: jsonString.data(using: .utf8)!)
            XCTAssertEqual(2, servers.count)
            XCTAssertEqual("kelvinstation.local", servers[0].hostname)
            XCTAssertEqual("photostation.local", servers[1].hostname)
            XCTAssertEqual(3, servers[0].ssdGroup.disks.count)
            XCTAssertEqual(3, servers[0].hddGroup.disks.count)
            XCTAssertEqual(1, servers[1].ssdGroup.disks.count)
            XCTAssertEqual(1, servers[1].hddGroup.disks.count)
        }catch{
            print(error)
        }
    }
    
}
