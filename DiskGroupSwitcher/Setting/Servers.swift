//
//  Settings.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Foundation

public class Disk : Codable {
    var volume:String = ""
    var online:Bool = false
    
    public init() {}
    
    public convenience init(volume: String) {
        self.init()
        self.volume = volume
    }
}

extension Disk : StackItemProtocol {
    
    public func getId() -> String {
        return self.volume
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
}

public class Servers {
    
    static let `stored` = Servers()
    
    private var servers:[Server] = []
    
    private init() {}
    
    public func isExistServer(hostname:String) -> Bool {
        if let server = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            return true
        }
        return false
    }
    
    public func addServer(hostname:String, ssdGroupName:String, hddGroupName:String) {
        if !self.isExistServer(hostname: hostname) {
            self.servers.append(Server(hostname: hostname, ssd: DiskGroup(name: ssdGroupName, disks: []), hdd: DiskGroup(name: hddGroupName, disks: [])))
        }
    }
    
    public func removeServer(hostname:String) {
        self.servers.removeAll { s in
            return s.hostname == hostname
        }
    }
    
    public func updateSsdGroupName(hostname:String, ssdGroupName:String) {
        if let server = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            server.ssdGroup.name = ssdGroupName
        }
    }
    
    public func updateHddGroupName(hostname:String, hddGroupName:String) {
        if let server = self.servers.first(where: { s in
            return s.hostname == hostname
        }) {
            server.hddGroup.name = hddGroupName
        }
        
    }
    
    public func addSsdDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.ssdGroup.disks.append(Disk(volume: volume))
            }
        }
    }
    
    public func addHddDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.hddGroup.disks.append(Disk(volume: volume))
            }
        }
    }
    
    public func removeSsdDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.ssdGroup.disks.removeAll { d in
                    return d.volume == volume
                }
            }
        }
    }
    
    public func removeHddDisk(hostname:String, volume:String) {
        for server in servers {
            if server.hostname == hostname {
                server.hddGroup.disks.removeAll { d in
                    return d.volume == volume
                }
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
        self.servers = self.fromJSON(jsonString)
        return servers
    }
    
    func saveServers() {
        let jsonString = self.toJSON()
        UserDefaults.standard.setValue(jsonString, forKey: "HOSTS")
    }
    
    
    
    public func toJSON() -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self.servers)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json!
        }catch{
            print(error)
            return "[]"
        }
    }
    
    public func fromJSON(_ jsonString:String) -> [Server] {
        print("decode: \(jsonString)")
        guard jsonString != "" else {return []}
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode([Server].self, from: jsonString.data(using: .utf8)!)
        }catch{
            print(error)
            return []
        }
    }
}
