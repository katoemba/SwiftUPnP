//
//  ServiceDefinition.swift
//
//  Copyright (c) 2023 Katoemba Software, (https://rigelian.net/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Berrie Kremers on 06/01/2023.
//

import Foundation
import XMLCoder

struct scdp: Decodable {
    let specVersion: SpecVersion
    let actionList: ActionList
    let serviceStateTable: ServiceStateTable
}

struct SpecVersion: Decodable {
    let major: Int
    let minor: Int
}

struct ActionList: Decodable {
    let action: [Action]
}

struct Action: Decodable {
    let name: String
    let argumentList: ArgumentList?
    
    var hasInput: Bool {
        inArguments.count > 0
    }
    var hasOutput: Bool {
        outArguments.count > 0
    }
    var inArguments: [Argument] {
        argumentList?.inArguments ?? []
    }
    var outArguments: [Argument] {
        argumentList?.outArguments ?? []
    }
}

struct ArgumentList: Decodable {
    let argument: [Argument]
    
    var inArguments: [Argument] {
        argument.filter { $0.direction == .in }
    }
    
    var outArguments: [Argument] {
        argument.filter { $0.direction == .out }
    }
}

struct Argument: Decodable {
    enum Direction: String, Decodable {
        case `in`
        case out
    }
    let name: String
    let direction: Direction
    let relatedStateVariable: String    
}

struct ServiceStateTable: Decodable {
    let stateVariable: [StateVariable]
}

struct StateVariable: Decodable {
    enum DataType: String, Decodable {
        case string
        case boolean
        case i4
        case ui4
        case i2
        case ui2
        case i1
        case ui1
        case int
        case uint
        case bin_base64 = "bin.base64"
        
        var swiftType: String {
            switch self {
            case .string:
                return "String"
            case .boolean:
                return "Bool"
            case .i4:
                return "Int32"
            case .ui4:
                return "UInt32"
            case .i2:
                return "Int16"
            case .ui2:
                return "UInt16"
            case .i1:
                return "Int8"
            case .ui1:
                return "UInt8"
            case .int:
                return "Int32"
            case .uint:
                return "UInt32"
            case .bin_base64:
                return "Data"
            }
        }
    }
    @Attribute var sendEvents: String
    var name: String
    var dataType: DataType
    var allowedValueList: AllowedValueList?
    
    var swiftType: String {
        if useEnum {
            return "\(name)Enum"
        }
        return  dataType.swiftType
    }
    
    var useEnum: Bool {
        dataType == .string && allowedValueList != nil
    }
}

struct AllowedValueList: Decodable {
    let allowedValue: [String]
}
