//
//  SSDPDiscoveryProtocol.swift
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
//  Created by Berrie Kremers on 03/03/2022.
//


import Foundation
import os.log

public enum UPnPError: Error {
    case alreadyConnected
    case networkingError(String)
}

enum SSDPMessageType: String {
    case searchResponse
    case availableNotification
    case updateNotification
    case unavailableNotification
}

class SSDPDiscovery: NSObject {
    let multicastGroupAddress = "239.255.255.250"
    let multicastUDPPort: UInt16 = 1900
    var types = [String]()
    
    func searchRequestData(forType type: String) -> Data? {
        ["M-SEARCH * HTTP/1.1",
         "HOST: \(multicastGroupAddress):\(multicastUDPPort)",
         "MAN: \"ssdp:discover\"",
         "ST: \(type)",
         "MX: 3",
         "USER-AGENT: \(UserAgentGenerator().UAString)\r\n\r\n"].joined(separator: "\r\n").data(using: .utf8)
    }
    
    func handleSSDPMessage(_ messageType: SSDPMessageType, headers: [String: String]) {
        if let usnRawValue = headers["usn"] {
            let usnComponents = usnRawValue.components(separatedBy: "::")
            if usnComponents.count == 2,
               let locationString = headers["location"],
               let locationURL = URL(string: locationString),
               /// NT = Notification Type - SSDP discovered from device advertisements
               /// ST = Search Target - SSDP discovered as a result of using M-SEARCH requests
                let ssdpType = (headers["st"] != nil ? headers["st"] : headers["nt"]) {
                
                let uuid = usnComponents[0]
                let deviceId = usnComponents[1]

                if types.contains(ssdpType) {
                    if messageType == .unavailableNotification {
                        Task {
                            await UPnPRegistry.shared.remove(UPnPDevice(uuid: uuid, deviceId: deviceId, deviceType: ssdpType, url: locationURL, lastSeen: Date()))
                        }
                    }
                    else {
                        Task {
                            await UPnPRegistry.shared.add(UPnPDevice(uuid: uuid, deviceId: deviceId, deviceType: ssdpType, url: locationURL, lastSeen: Date()))
                        }
                    }
                }
            }
        }
    }
    
    func processData(_ data: Data) {
        if let message = String(data: data, encoding: .utf8) {
            var httpMethodLine: String?
            var headers = [String: String]()
            
            message.enumerateLines(invoking: { (line, stop) -> () in
                if httpMethodLine == nil {
                    httpMethodLine = line
                } else {
                    let parts = line.components(separatedBy: ": ")
                    if parts.count == 2 {
                        headers[String(parts[0].lowercased())] = String(parts[1])
                    }
                }
            })
            
            if let httpMethodLine = httpMethodLine {
                let nts = headers["nts"]
                switch (httpMethodLine, nts) {
                case ("HTTP/1.1 200 OK", _):
                    handleSSDPMessage(.searchResponse, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:alive":
                    handleSSDPMessage(.availableNotification, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:update":
                    handleSSDPMessage(.updateNotification, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:byebye":
                    headers["location"] = headers["host"] // byebye messages don't have a location
                    handleSSDPMessage(.unavailableNotification, headers: headers)
                default:
                    return
                }
            }
        }
    }
}
