//
//  Extensions.swift
//  DiskGroupSwitcher
//
//  Created by Kelvin Wong on 2023/11/25.
//

import Foundation


extension String {
    func toJSONArray() -> [JSON] {
        if let data = self.data(using: .utf8) {
            do {
                let json = try JSON(data: data)
                return json.array ?? []
            }catch{
                print(error)
            }
        }
        return []
    }
}

extension Array {
    func toJSONString() -> String {
        let json = JSON(self)
        let jsonString = json.rawString(.utf8, options: [.fragmentsAllowed, .withoutEscapingSlashes]) ?? "[]"
        return jsonString
    }
    
    func appending<S>(_ newElements: S) -> [Element] where Element == S.Element, S : Sequence  {
        var arr = self
        arr.append(contentsOf: newElements)
        return arr
    }
}
