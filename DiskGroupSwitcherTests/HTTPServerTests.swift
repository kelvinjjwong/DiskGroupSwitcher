//
//  HTTPServerTests.swift
//  DiskGroupSwitcherTests
//
//  Created by kelvinwong on 2023/12/1.
//

import XCTest
import FlyingFox
@testable import DiskGroupSwitcher

final class HTTPServerTests: XCTestCase {
    
    func testHTTPServer() async {
        
        let server = HTTPServer(port: 18080)
        let task = Task { 
            await server.appendRoute("/health") { request in
              try await Task.sleep(nanoseconds: 1_000_000_000)
              return HTTPResponse(statusCode: .ok)
            }
            try await server.start()
        }
        print("http server started")
    }
    
}
