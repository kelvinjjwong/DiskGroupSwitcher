//
//  Defaults.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/28.
//

import Foundation

public class Defaults {
    
    static let `get` = Defaults()
    
    private init() {}
    
    public func httpPort() -> Int {
        return 18080
    }
}
