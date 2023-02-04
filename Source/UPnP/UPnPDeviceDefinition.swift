//
//  UPnPDeviceDefinition.swift
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
