//
//  Settings.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Foundation
import LoggerFactory

public class Disk : Codable {
    var volume:String = ""
    var online:Bool = false
    var softlink:String = ""
    
    public init() {}
    
    public convenience init(volume: String, link: String = "") {
        self.init()
        self.volume = volume
        self.softlink = link
    }
    
    public func isOnline() -> Bool {
        guard self.volume != "" else {return false}
        let volume = "/Volumes/\(self.volume)"
        return volume.isVolumeExists()
    }
    
    public func isLinked() -> Bool {
        guard self.softlink != "" else {return true}
        return self.softlink.getSoftlinkTargetFromThisPath() == "/Volumes/\(self.volume)"
    }
    
    public func unlink() {
        self.softlink.unlink()
    }
    
    public func link() {
        self.softlink.link(to: "/Volumes/\(self.volume)")
    }
}

extension Disk {
    
    public func getId() -> String {
        return "/Volume/\(self.volume)"
    }
    
    public func getName() -> String {
        return "/Volume/\(self.volume)"
    }
}

public class DiskGroup : Codable  {
    
    var name:String = ""
    var selected:Bool = false
    var disks:[Disk] = []
    
    public init() {}
    
    public convenience init(name: String, disks:[Disk]) {
        self.init()
        self.name = name
        self.disks = disks
    }
    
    public func isOnline() -> Bool {
        let array = self.disks.map { disk in
            return disk.isOnline()
        }
        return !array.contains(false)
    }
    
    public func volumes() -> [String] {
        return disks.map { "/Volumes/\($0.volume)" }
    }
    
}

public class Server : Codable {
    
    var hostname:String = ""
    var online:Bool = false
    var ssdGroup:DiskGroup = DiskGroup()
    var hddGroup:DiskGroup = DiskGroup()
    
    public init() {}
    
    public convenience init(hostname:String, ssd:DiskGroup, hdd:DiskGroup) {
        self.init()
        self.hostname = hostname
        self.ssdGroup = ssd
        self.hddGroup = hdd
    }
    
    public func getSsdDisks() -> [[String:String]] {
        var ssdVolumes:[[String:String]] = []
        for disk in self.ssdGroup.disks {
            var volume:[String:String] = [:]
            volume["volume"] = disk.getName()
            volume["status"] = disk.online ? "online" : "offline"
            volume["status#textColor"] = disk.online ? "00FF00" : "7F7F7F"
            volume["softlink"] = disk.softlink
            ssdVolumes.append(volume)
        }
        return ssdVolumes
    }
    
    public func getHddDisks() -> [[String:String]] {
        var hddVolumes:[[String:String]] = []
        for disk in self.hddGroup.disks {
            var volume:[String:String] = [:]
            volume["volume"] = disk.getName()
            volume["status"] = disk.online ? "online" : "offline"
            volume["status#textColor"] = disk.online ? "00FF00" : "7F7F7F"
            volume["softlink"] = disk.softlink
            hddVolumes.append(volume)
        }
        return hddVolumes
    }
}

public class Servers {
    
    let logger = LoggerFactory.get(category: "Servers")
    
    static let `stored` = Servers()
    
    private var servers:[Server] = []
    
    private init() {}
    
    public func count() -> Int {
        return self.servers.count
    }
    
    public func isExistServer(hostname:String) -> Bool {
        if let _ = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            return true
        }
        return false
    }
    
    public func addServer(_ server:Server) {
        self.servers.append(server)
    }
    
    public func hostnames() -> [String] {
        return self.servers.map { s in
            return s.hostname
        }
    }
    
    public func getServer(index: Int) -> Server {
        return self.servers[index]
    }
    
    public func addServer(hostname:String, ssdGroupName:String, hddGroupName:String) {
        if !self.isExistServer(hostname: hostname) {
            self.servers.append(Server(hostname: hostname, ssd: DiskGroup(name: ssdGroupName, disks: []), hdd: DiskGroup(name: hddGroupName, disks: [])))
            self.saveServers()
        }
    }
    
    public func removeServer(hostname:String) {
        self.servers.removeAll { s in
            return s.hostname == hostname
        }
        self.saveServers()
    }
    
    public func updateSsdGroupName(hostname:String, ssdGroupName:String) {
        if let server = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            server.ssdGroup.name = ssdGroupName
            self.saveServers()
        }
    }
    
    public func updateHddGroupName(hostname:String, hddGroupName:String) {
        if let server = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            server.hddGroup.name = hddGroupName
            self.saveServers()
        }
        
    }
    
    public func addSsdDisk(hostname:String, volume:String, link:String = "") {
        for server in servers {
            if server.hostname == hostname {
                if let _ = server.ssdGroup.disks.first(where: { d in
                    return d.volume == volume
                }) {
                    // do nothing
                }else {
                    server.ssdGroup.disks.append(Disk(volume: volume, link: link))
                    self.saveServers()
                }
            }
        }
    }
    
    public func addHddDisk(hostname:String, volume:String, link:String = "") {
        for server in servers {
            if server.hostname == hostname {
                if let _ = server.hddGroup.disks.first(where: { d in
                    return d.volume == volume
                }) {
                    // do nothing
                }else {
                    server.hddGroup.disks.append(Disk(volume: volume, link: link))
                    self.saveServers()
                }
            }
        }
    }
    
    public func removeSsdDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.ssdGroup.disks.removeAll { d in
                    return d.volume == volume
                }
                self.saveServers()
            }
        }
    }
    
    public func removeHddDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.hddGroup.disks.removeAll { d in
                    return d.volume == volume
                }
                self.saveServers()
            }
        }
    }
    
    public func updateServerStatus(hostname:String, state:Bool) {
        for server in servers {
            if server.hostname == hostname {
                server.online = state
            }
        }
    }
    
    public func updateDiskStatus(hostname:String, volume:String, state:Bool) {
        for server in servers {
            if server.hostname == hostname {
                for disk in server.ssdGroup.disks {
                    if disk.volume == volume {
                        disk.online = state
                    }
                }
                for disk in server.hddGroup.disks {
                    if disk.volume == volume {
                        disk.online = state
                    }
                }
            }
        }
    }
    
    public func cleanAllStatus() {
        for server in servers {
            server.online = false
            for disk in server.ssdGroup.disks {
                disk.online = false
            }
            for disk in server.hddGroup.disks {
                disk.online = false
            }
        }
    }
    
    func loadServers() -> [Server] {
        let jsonString = UserDefaults.standard.get(key: "HOSTS", defaultValue: "[]")
        self.logger.log("load: \(jsonString)")
        self.servers = self.fromJSON(jsonString)
        return servers
    }
    
    func saveServers() {
        let jsonString = self.toJSON()
        self.logger.log("save: \(jsonString)")
        UserDefaults.standard.setValue(jsonString, forKey: "HOSTS")
    }
    
    
    
    public func toJSON() -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self.servers)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json!
        }catch{
            self.logger.log(.error, error)
            return "[]"
        }
    }
    
    public func fromJSON(_ jsonString:String) -> [Server] {
//        print("decode: \(jsonString)")
        guard jsonString != "" else {return []}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode([Server].self, from: jsonString.data(using: .utf8)!)
        }catch{
            self.logger.log(.error, error)
            return []
        }
    }
}
