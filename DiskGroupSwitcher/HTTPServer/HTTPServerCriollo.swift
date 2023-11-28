//
//  HTTPServerCriollo.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation
import LoggerFactory
import Criollo

public class HTTPServerCriollo : HTTPServerProtocol {
    
    var logger = LoggerFactory.get(category: "HTTP", subCategory: "Criollo")
    
    private var httpServer:CRHTTPServer?
    private var port:UInt = Defaults.get.httpPort()
    
    public func start() {
        let server = CRHTTPServer()
        
        server.get("/") { (req, res, next) in
            res.send(HealthCheck().toJSON())
        }
        
        server.get("/status/:volume") { (req, res, next) in
            self.logger.log(.trace, "getting status of volume: \(req.query["volume"] ?? "")")
            
            if let _volume = req.query["volume"], _volume != "" {
                let volume = "/Volumes/\(_volume)"
                res.send(["mounted":volume.isVolumeExists(), "volume":_volume])
            }else{
                res.send(["mounted":false, "error": "GET /status/:volume missing parameter :volume in query"])
                
            }
        }
        
        var serverError:NSError? = nil
        if !server.startListening(&serverError, portNumber: self.port) {
            self.logger.log(.error, serverError ?? "unknown error")
            self.logger.log(.error, "HTTP Server cannot be started.")
            fatalError("HTTP Server cannot be started.")
        }
        self.httpServer = server
        self.logger.log("HTTP Server started at http://localhost:\(port)/")
    }
    
    public func stop() {
        if let server = self.httpServer {
            self.logger.log("Terminating HTTP Server.")
            server.stopListening()
        }
    }
}
