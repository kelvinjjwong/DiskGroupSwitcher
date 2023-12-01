//
//  HTTPServer.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation

public protocol HTTPServerProtocol {
    func start()
    func stop()
}

public enum HTTPServerEngine {
    case Criollo
    case FlyingFox
}

public class HTTPServer : HTTPServerProtocol {
    
    private var impl:HTTPServerProtocol
    
    public static let `default` = HTTPServer(.FlyingFox)
    
    private init(_ engine:HTTPServerEngine) {
        if engine == .FlyingFox {
            self.impl = HTTPServerFlyingFox()
        }else{
            fatalError("Unsupported init parameter.")
        }
    }
    
    public func start() {
        self.impl.start()
    }
    
    public func stop() {
        self.impl.stop()
        
    }
}
