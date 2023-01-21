//
//  UPnPRegistry.swift
//  
//
//  Created by Berrie Kremers on 08/01/2023.
//

import Foundation
import Combine
import Swifter
import os.log

public class UPnPRegistry {
    public static let shared = UPnPRegistry()
    
    private let discoveryEngine = SSDPDiscovery()
    
    @MainActor
    public var devices = [UPnPDevice]()
    private var deviceAddedSubject = PassthroughSubject<UPnPDevice, Never>()
    public var deviceAdded: AnyPublisher<UPnPDevice, Never> {
        deviceAddedSubject.eraseToAnyPublisher()
    }
    private var deviceRemovedSubject = PassthroughSubject<UPnPDevice, Never>()
    public var deviceRemoved: AnyPublisher<UPnPDevice, Never> {
        deviceRemovedSubject.eraseToAnyPublisher()
    }
    
    private var httpServer: HttpServer
    private let httpServerPort: UInt16
    private let eventCallBackPath = "/Event/\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    private var eventCallbackUrl: URL?
    private let eventSubject = PassthroughSubject<(String, Data), Never>()
    private lazy var eventPublisher: AnyPublisher<(String, Data), Never> = {
        eventSubject.share().eraseToAnyPublisher()
    }()
    
    init() {
        httpServerPort = IPHelper.freePortFromRange(range: 51000..<51099)
        httpServer = HttpServer()
        httpServer[eventCallBackPath] = { [weak self] request in
            guard let self else { return HttpResponse.internalServerError(.text("Self released")) }
            guard request.method.lowercased() == "notify" else { return HttpResponse.internalServerError(.text("Only handling NOTIFY")) }
            
            let headerFields = Dictionary(uniqueKeysWithValues: request.headers.map { key, value in (key.uppercased(), value) })
            if let sid = headerFields["SID"] {
                let data = Data(fromArray: request.body)
                self.eventSubject.send((sid, data))
            }
            
            return HttpResponse.ok(.text(""))
        }

        Task {
            await startHTTPServer()
        }
    }
    
    public func startDiscovery() throws {
        try discoveryEngine.startDiscovery(forTypes: ["urn:schemas-upnp-org:device:MediaServer:1",
                                                      "urn:linn-co-uk:device:Source:1",
                                                      "urn:av-openhome-org:device:Source:1"])
        
        discoveryEngine.searchRequest()
    }
    
    public func stopDiscovery() {
        discoveryEngine.stopDiscovery()
    }
    
    @MainActor
    private func startHTTPServer() {
        do {
            try httpServer.start(httpServerPort)
            
            eventCallbackUrl = callbackUrl()
            if let eventCallbackUrl = eventCallbackUrl {
                for device in devices {
                    for service in device.services {
                        service.eventCallbackUrl = eventCallbackUrl
                    }
                }
            }
        }
        catch {
            Logger.swiftUPnP.error("Couldn't start http server on port \(self.httpServerPort)")
            Logger.swiftUPnP.error("\(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func stopHTTPServer() {
        if httpServer.operating {
            httpServer.stop()
            eventCallbackUrl = nil
        }
    }
    
    func callbackUrl() -> URL? {
        if let ipAddress = IPHelper.getInterfaceIPAddress(interfaceNames: ["en0", "en1"]) {
            return  URL(string: "http://\(ipAddress):\(httpServerPort)\(eventCallBackPath)")
        }
        return nil
    }
    
    @MainActor
    func add(_ device: UPnPDevice) {
        guard devices.contains(where: { $0.id == device.id }) == false else { return }
        devices.append(device)
        
        Task {
            await device.loadRoot()
            if let deviceServices = device.deviceDefinition?.device.serviceList?.service {
                for deviceService in deviceServices {
                    guard let service = typedService(device: device, serviceUrn: deviceService.serviceType) else { continue }
                    
                    await service.loadScdp()
                    device.add(service)
                }
            }
            
            device.servicesLoaded = true
            deviceAddedSubject.send(device)
        }
    }

    @MainActor
    func remove(_ device: UPnPDevice) {
        guard let device = devices.first(where: { $0.id == device.id }) else { return }
        devices.removeAll(where: { $0.id == device.id })
        deviceRemovedSubject.send(device)
    }

    func typedService(device: UPnPDevice, serviceUrn: String) -> UPnPService? {
        guard let deviceServices = device.deviceDefinition?.device.serviceList?.service,
              let deviceService = deviceServices.first(where: { $0.serviceType == serviceUrn }) else { return nil }
        
        let baseURL = URL(string: "\(device.url.scheme!)://\(device.url.host!):\(device.url.port!)")
        switch serviceUrn {
        case "urn:av-openhome-org:service:Credentials:1":
            return OpenHomeCredentials1Service(device: device,
                                               controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                               scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                               eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                               serviceType: deviceService.serviceType,
                                               serviceId: deviceService.serviceId,
                                               eventPublisher: eventPublisher,
                                               eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Info:1":
            return OpenHomeInfo1Service(device: device,
                                        controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                        scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                        eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                        serviceType: deviceService.serviceType,
                                        serviceId: deviceService.serviceId,
                                        eventPublisher: eventPublisher,
                                        eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Pins:1":
            return OpenHomePins1Service(device: device,
                                        controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                        scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                        eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                        serviceType: deviceService.serviceType,
                                        serviceId: deviceService.serviceId,
                                        eventPublisher: eventPublisher,
                                        eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Playlist:1":
            return OpenHomePlaylist1Service(device: device,
                                            controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                            scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                            eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                            serviceType: deviceService.serviceType,
                                            serviceId: deviceService.serviceId,
                                            eventPublisher: eventPublisher,
                                            eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:PlaylistManager:1":
            return OpenHomePlaylistManager1Service(device: device,
                                                   controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                                   scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                                   eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                                   serviceType: deviceService.serviceType,
                                                   serviceId: deviceService.serviceId,
                                                   eventPublisher: eventPublisher,
                                                   eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Product:1":
            return OpenHomeProduct1Service(device: device,
                                           controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                           scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                           eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                           serviceType: deviceService.serviceType,
                                           serviceId: deviceService.serviceId,
                                           eventPublisher: eventPublisher,
                                           eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Radio:1":
            return OpenHomeRadio1Service(device: device,
                                         controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                         scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                         eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                         serviceType: deviceService.serviceType,
                                         serviceId: deviceService.serviceId,
                                         eventPublisher: eventPublisher,
                                         eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Time:1":
            return OpenHomeTime1Service(device: device,
                                        controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                        scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                        eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                        serviceType: deviceService.serviceType,
                                        serviceId: deviceService.serviceId,
                                        eventPublisher: eventPublisher,
                                        eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Transport:1":
            return OpenHomeTransport1Service(device: device,
                                             controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                             scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                             eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                             serviceType: deviceService.serviceType,
                                             serviceId: deviceService.serviceId,
                                             eventPublisher: eventPublisher,
                                             eventCallbackUrl: eventCallbackUrl)
        case "urn:av-openhome-org:service:Volume:1":
            return OpenHomeVolume1Service(device: device,
                                          controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                          scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                          eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                          serviceType: deviceService.serviceType,
                                          serviceId: deviceService.serviceId,
                                          eventPublisher: eventPublisher,
                                          eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:ConnectionManager:1":
            return ConnectionManager1Service(device: device,
                                             controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                             scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                             eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                             serviceType: deviceService.serviceType,
                                             serviceId: deviceService.serviceId,
                                             eventPublisher: eventPublisher,
                                             eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:ContentDirectory:1":
            return ContentDirectory1Service(device: device,
                                            controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                            scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                            eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                            serviceType: deviceService.serviceType,
                                            serviceId: deviceService.serviceId,
                                            eventPublisher: eventPublisher,
                                            eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:AVTransport:1":
            return AVTransport1Service(device: device,
                                       controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                       scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                       eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                       serviceType: deviceService.serviceType,
                                       serviceId: deviceService.serviceId,
                                       eventPublisher: eventPublisher,
                                       eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:RenderingControl:1":
            return RenderingControl1Service(device: device,
                                            controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                                            scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                                            eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                                            serviceType: deviceService.serviceType,
                                            serviceId: deviceService.serviceId,
                                            eventPublisher: eventPublisher,
                                            eventCallbackUrl: eventCallbackUrl)
        default:
            return UPnPService(device: device,
                               controlUrl: URL(string: deviceService.controlURL, relativeTo: baseURL)!,
                               scpdUrl: URL(string: deviceService.SCPDURL, relativeTo: baseURL)!,
                               eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL)!,
                               serviceType: deviceService.serviceType,
                               serviceId: deviceService.serviceId,
                               eventPublisher: eventPublisher,
                               eventCallbackUrl: eventCallbackUrl)
        }
    }
}

