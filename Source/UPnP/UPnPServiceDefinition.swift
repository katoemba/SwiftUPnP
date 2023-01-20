//
//  UPnPServiceDefinition.swift
//  UPnPGenerator
//
//  Created by Berrie Kremers on 06/01/2023.
//

import Foundation
import XMLCoder

struct UPnPServiceDefinition: Decodable {
    let specVersion: SpecVersion
    let actionList: ActionList
    let serviceStateTable: ServiceStateTable
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
