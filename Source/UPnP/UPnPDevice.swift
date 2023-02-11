//
//  UPnPDevice.swift
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
//  Created by Berrie Kremers on 08/01/2023.
//

import Foundation
import XMLCoder
import os.log

public class UPnPDevice: Equatable, Identifiable, Hashable {
    public let uuid: String
    public let deviceId: String
    public let deviceType: String
    public let url: URL
    
    public var deviceDefinition: UPnPDeviceDefinition?
    @MainActor
    public var services = [UPnPService]()
    @MainActor
    public internal(set) var servicesLoaded: Bool
    
    internal init(uuid: String, deviceId: String, deviceType: String, url: URL) {
        self.uuid = uuid
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.url = url
        self.servicesLoaded = false
    }

    public static func == (lhs: UPnPDevice, rhs: UPnPDevice) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: String {
        "\(uuid)::\(deviceId)"
    }

    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    var description: String {
        "Device urn: \(id)\nurl: \(url)"
    }
    
    @MainActor
    func add(_ service: UPnPService) {
        services.append(service)
    }
    
    func loadRoot() async {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            Logger.swiftUPnP.error("Error: couldn't load device description from \(self.url.absoluteString)")
            return
        }
        
        do {
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = false
            deviceDefinition = try decoder.decode(UPnPDeviceDefinition.self, from: data)
            Logger.swiftUPnP.debug("Device parsed \(self.deviceDefinition!.device.friendlyName) - \(self.deviceDefinition!.device.deviceType  )")
        }
        catch DecodingError.dataCorrupted(let context) {
            Logger.swiftUPnP.error("\(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            Logger.swiftUPnP.error("\(key.stringValue) was not found, \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            Logger.swiftUPnP.error("\(type) was expected, \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            Logger.swiftUPnP.error("no value was found for \(type), \(context.debugDescription)")
        } catch {
            Logger.swiftUPnP.error("Unknown error \(error.localizedDescription)")
        }
    }    
}

@MainActor
extension UPnPDevice {
    public var connectionManager1Service: ConnectionManager1Service? {
        services.first(where: { $0.serviceType == "urn:schemas-upnp-org:service:ConnectionManager:1" }) as? ConnectionManager1Service
    }
    
    public var contentDirectory1Service: ContentDirectory1Service? {
        services.first(where: { $0.serviceType == "urn:schemas-upnp-org:service:ContentDirectory:1" }) as? ContentDirectory1Service
    }
    
    public var openHomeCredentials1Service: OpenHomeCredentials1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Credentials:1" }) as? OpenHomeCredentials1Service
    }
    
    public var openHomeInfo1Service: OpenHomeInfo1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Info:1" }) as? OpenHomeInfo1Service
    }
    
    public var openHomePins1Service: OpenHomePins1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Pins:1" }) as? OpenHomePins1Service
    }
    
    public var openHomePlaylist1Service: OpenHomePlaylist1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Playlist:1" }) as? OpenHomePlaylist1Service
    }
    
    public var openHomePlaylistManager1Service: OpenHomePlaylistManager1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:PlaylistManager:1" }) as? OpenHomePlaylistManager1Service
    }
    
    public var openHomeProduct1Service: OpenHomeProduct1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Product:1" }) as? OpenHomeProduct1Service
    }
    
    public var openHomeProduct2Service: OpenHomeProduct2Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Product:2" }) as? OpenHomeProduct2Service
    }
    
    public var openHomeRadio1Service: OpenHomeRadio1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Radio:1" }) as? OpenHomeRadio1Service
    }
    
    public var openHomeTime1Service: OpenHomeTime1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Time:1" }) as? OpenHomeTime1Service
    }
    
    public var openHomeTransport1Service: OpenHomeTransport1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Transport:1" }) as? OpenHomeTransport1Service
    }
    
    public var openHomeVolume1Service: OpenHomeVolume1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Volume:1" }) as? OpenHomeVolume1Service
    }
    
    public var openHomeVolume2Service: OpenHomeVolume2Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Volume:2" }) as? OpenHomeVolume2Service
    }
    
    public var openHomeSender1Service: OpenHomeSender1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Sender:1" }) as? OpenHomeSender1Service
    }
    
    public var openHomeReceiver1Service: OpenHomeReceiver1Service? {
        services.first(where: { $0.serviceType == "urn:av-openhome-org:service:Receiver:1" }) as? OpenHomeReceiver1Service
    }
}
