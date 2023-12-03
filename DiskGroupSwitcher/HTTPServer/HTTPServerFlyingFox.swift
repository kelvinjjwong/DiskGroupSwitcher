//
//  HTTPServerFlyingFox.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/12/1.
//

import Foundation
import LoggerFactory
import FlyingFox


public class HTTPServerFlyingFox : HTTPServerProtocol {
    
    
    var logger = LoggerFactory.get(category: "HTTP", subCategory: "FlyingFox")
    private var port:UInt16 = UInt16(Defaults.get.httpPort())
    
    public func start() {
        
        let server = FlyingFox.HTTPServer(port: self.port)
        let _ = Task {
            await server.appendRoute("GET /") { request in
                
                return HTTPResponse(statusCode: .ok, body: HealthCheck().toJSON().data())
            }
            
            await server.appendRoute("GET /status/*") { request in
                let _volume = request.path.replacingFirstOccurrence(of: "/status/", with: "")
                var rtn = "{}".data()
                if _volume != "" {
                    let volume = "/Volumes/\(_volume)"
                    rtn = ["mounted": volume.isVolumeExists(), "volume":_volume].json.data()
                }else{
                    rtn = ["mounted":false, "error": "GET /status/:volume missing parameter :volume in query"].json.data()
                }
                return HTTPResponse(statusCode: .ok, body: rtn)
            }
            
            await server.appendRoute("POST /linkstatus") { request in
                struct R : Decodable {
                    var volume:String
                    var softlink:String
                }
                
                if let r = R.fromJSON(try await request.bodyData.string()) {
                    var rtn = "{}".data()
                    
                    if r.softlink == "" {
                        rtn = ["linked": true, "volume": r.volume, "softlink": r.softlink].json.data()
                    }else{
                        rtn = ["linked": r.softlink.getSoftlinkTargetFromThisPath() == "/Volumes/\(r.volume)", "volume": r.volume, "softlink": r.softlink].json.data()
                    }
                    return HTTPResponse(statusCode: .ok, body: rtn)
                }else{
                    return HTTPResponse(statusCode: .badRequest)
                }
            }
            
            await server.appendRoute("POST /unlink/all") { request in
                struct R : Decodable {
                    var volume:String
                    var softlink:String
                    var group:String
                }
                if let array = [R].fromJSON(try await request.bodyData.string()) {
                    if array.isEmpty {
                        return HTTPResponse(statusCode: .badRequest)
                    }
                    for r in array {
                        let disk = Disk(volume: r.volume, link: r.softlink)
                        self.logger.log("unlinking \(r.softlink)")
                        disk.unlink()
                    }
                    return HTTPResponse(statusCode: .ok)
                }else{
                    return HTTPResponse(statusCode: .badRequest)
                }
            }
            
            await server.appendRoute("POST /link/ssd") { request in
                struct R : Decodable {
                    var volume:String
                    var softlink:String
                    var group:String
                }
                if let array = [R].fromJSON(try await request.bodyData.string()) {
                    if array.isEmpty {
                        return HTTPResponse(statusCode: .badRequest)
                    }
                    for r in array {
                        let disk = Disk(volume: r.volume, link: r.softlink)
                        self.logger.log("unlinking \(r.softlink)")
                        disk.unlink()
                    }
                    for r in array {
                        if r.group == "ssd" {
                            let disk = Disk(volume: r.volume, link: r.softlink)
                            self.logger.log("linking \(r.softlink) to \(r.group): /Volumes/\(r.volume)")
                            disk.link()
                        }
                    }
                    return HTTPResponse(statusCode: .ok)
                }else{
                    return HTTPResponse(statusCode: .badRequest)
                }
            }
            
            await server.appendRoute("POST /link/hdd") { request in
                struct R : Decodable {
                    var volume:String
                    var softlink:String
                    var group:String
                }
                if let array = [R].fromJSON(try await request.bodyData.string()) {
                    if array.isEmpty {
                        return HTTPResponse(statusCode: .badRequest)
                    }
                    for r in array {
                        let disk = Disk(volume: r.volume, link: r.softlink)
                        self.logger.log("unlinking \(r.softlink)")
                        disk.unlink()
                    }
                    for r in array {
                        if r.group == "hdd" {
                            let disk = Disk(volume: r.volume, link: r.softlink)
                            self.logger.log("linking \(r.softlink) to \(r.group): /Volumes/\(r.volume)")
                            disk.link()
                        }
                    }
                    return HTTPResponse(statusCode: .ok)
                }else{
                    return HTTPResponse(statusCode: .badRequest)
                }
            }
            
            await server.appendRoute("GET /setting") { request in
                let rtn = Servers.stored.toJSON().data()
                return HTTPResponse(statusCode: .ok, body: rtn)
            }
            
            try await server.start()
        }
    }
    
    public func stop() {
        
    }
    
}

extension Dictionary{
    
    var json: String {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return "{}"
        }
        return String(data: theJSONData, encoding: .utf8) ?? "{}"
    }
}

extension String {
    func data() -> Data {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)!
    }
}

extension Data {
    
    func string() -> String {
        return String(decoding: self, as: UTF8.self)
    }
}

extension Decodable {
    
    static func fromJSON(_ jsonString:String) -> Self? {
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(Self.self, from: jsonString.data(using: .utf8)!)
        }catch{
            return nil
        }
    }
}
