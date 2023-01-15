//
//  XMLParserSupport.swift
//  
//
//  Created by Berrie Kremers on 07/01/2023.
//

import Foundation

public enum ServiceParseError: Error {
    case noValidResponse
}

extension Data {
    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}
