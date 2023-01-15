//
//  UPnPRegistry.swift
//  
//
//  Created by Berrie Kremers on 08/01/2023.
//

import Foundation
import Combine
import GCDWebServer

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
    
    private var httpServer: GCDWebServer
    private let httpServerPort: UInt = 58123 // TODO: use a free port, don't hardcode
    private let eventCallBackPath = "/Event/\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    private var eventCallbackUrl: URL?
    private let eventSubject = PassthroughSubject<(String, Data), Never>()
    private lazy var eventPublisher: AnyPublisher<(String, Data), Never> = {
        eventSubject.share().eraseToAnyPublisher()
    }()
    
    init() {
        httpServer = GCDWebServer()
        
        httpServer.addHandler(forMethod: "NOTIFY", path: self.eventCallBackPath, request: GCDWebServerDataRequest.self) { [weak self] (request: GCDWebServerRequest!) -> GCDWebServerResponse in
            guard let self else { return GCDWebServerResponse() }
            
            if let dataRequest = request as? GCDWebServerDataRequest {
                let headerFields = Dictionary(uniqueKeysWithValues: dataRequest.headers.map { key, value in (key.uppercased(), value) })
                if let sid = headerFields["SID"] {
                    self.eventSubject.send((sid, dataRequest.data))
                }
            }
            
            return GCDWebServerResponse()
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
        let options: [String: Any] = [GCDWebServerOption_Port: httpServerPort]
        try? httpServer.start(options: options)
        
        eventCallbackUrl = callbackUrl()
        if let eventCallbackUrl = eventCallbackUrl {
            for device in devices {
                for service in device.services {
                    service.eventCallbackUrl = eventCallbackUrl
                }
            }
        }
    }
    
    @MainActor
    private func stopHTTPServer() {
        if httpServer.isRunning {
            httpServer.stop()
            eventCallbackUrl = nil
        }
    }
    
    func callbackUrl() -> URL? {
        if let serverURL = httpServer.serverURL {
            return URL(string: eventCallBackPath, relativeTo: serverURL)
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
