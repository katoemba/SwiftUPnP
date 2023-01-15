//
//  UPnPDeviceDefinition.swift
//  
//
//  Created by Berrie Kremers on 09/01/2023.
//
import Foundation
import XMLCoder

public struct UPnPDeviceDefinition: Decodable {
    public let specVersion: SpecVersion
    public let device: Device
}

public struct SpecVersion: Decodable {
    public let major: Int
    public let minor: Int
}

public struct Device: Decodable {
    public let deviceType: String
    public let friendlyName: String
    public let manufacturer: String
    public let manufacturerURL: String?
    public let modelDescription: String?
    public let modelName: String
    public let modelNumber: String?
    public let modelURL: String?
    public let serialNumber: String?
    public let UDN: String
    public let UPC: String?

    public let iconList: IconList?
    public let serviceList: ServiceList?
    
    public let presentationURL: String?
}

public struct IconList: Decodable {
    public let icon: [Icon]
}

public struct Icon: Decodable {
    public let mimetype: String
    public let width: Int
    public let height: Int
    public let depth: Int
    public let url: String
}

public struct ServiceList: Decodable {
    public let service: [Service]
}

public struct Service: Decodable {
    public let serviceType: String
    public let serviceId: String
    public let SCPDURL: String
    public let controlURL: String
    public let eventSubURL: String
}
