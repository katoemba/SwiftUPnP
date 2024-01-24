//
// Product: 
// Package: 
//
// Created by Berrie Kremers on 17/01/2024
// Copyright © 2018-2023 Katoemba Software. All rights reserved.
//
	

import XCTest
@testable import SwiftUPnP
import Mocker
import Combine

final class MockedData {
    public static let openHomeRendererXML: URL = Bundle.module.url(forResource: "OpenHomeRendererDevice", withExtension: "xml")!
    public static let mediaServerXML: URL = Bundle.module.url(forResource: "MediaServerDevice", withExtension: "xml")!
    public static let config1XML: URL = Bundle.module.url(forResource: "OpenHomeConfig1Service", withExtension: "xml")!
    public static let credentials1XML: URL = Bundle.module.url(forResource: "OpenHomeCredentials1Service", withExtension: "xml")!
    public static let info1XML: URL = Bundle.module.url(forResource: "OpenHomeInfo1Service", withExtension: "xml")!
    public static let playlist1XML: URL = Bundle.module.url(forResource: "OpenHomePlaylist1Service", withExtension: "xml")!
    public static let oauth1XML: URL = Bundle.module.url(forResource: "OpenHomeOAuth1Service", withExtension: "xml")!
    public static let playlistManager1XML: URL = Bundle.module.url(forResource: "OpenHomePlaylistManager1Service", withExtension: "xml")!
    public static let product1XML: URL = Bundle.module.url(forResource: "OpenHomeProduct1Service", withExtension: "xml")!
    public static let product2XML: URL = Bundle.module.url(forResource: "OpenHomeProduct2Service", withExtension: "xml")!
    public static let radio1XML: URL = Bundle.module.url(forResource: "OpenHomeRadio1Service", withExtension: "xml")!
    public static let receiver1XML: URL = Bundle.module.url(forResource: "OpenHomeReceiver1Service", withExtension: "xml")!
    public static let sender1XML: URL = Bundle.module.url(forResource: "OpenHomeSender1Service", withExtension: "xml")!
    public static let timeXML1: URL = Bundle.module.url(forResource: "OpenHomeTime1Service", withExtension: "xml")!
    public static let transportXML1: URL = Bundle.module.url(forResource: "OpenHomeTransport1Service", withExtension: "xml")!
    public static let volume1XML: URL = Bundle.module.url(forResource: "OpenHomeVolume1Service", withExtension: "xml")!
    public static let volume2XML: URL = Bundle.module.url(forResource: "OpenHomeVolume2Service", withExtension: "xml")!
    public static let avtransport1XML: URL = Bundle.module.url(forResource: "AVTransport1Service", withExtension: "xml")!
    public static let connectionManager1XML: URL = Bundle.module.url(forResource: "ConnectionManager1Service", withExtension: "xml")!
    public static let contentDirectory1XML: URL = Bundle.module.url(forResource: "ContentDirectory1Service", withExtension: "xml")!
    public static let renderingControl1XML: URL = Bundle.module.url(forResource: "RenderingControl1Service", withExtension: "xml")!
}

extension Bundle {
#if !SWIFT_PACKAGE
    static let module = Bundle(for: MockedData.self)
#endif
}

internal extension URL {
    /// Returns a `Data` representation of the current `URL`. Force unwrapping as it's only used for tests.
    var data: Data {
        return try! Data(contentsOf: self)
    }
}

extension Mock.DataType {
    public static let xml = Mock.DataType(name: "xml", headerValue: "application/xml; charset=utf-8")
}

final class SwiftUPnPTests: XCTestCase {
    let openHomeBase = "http://10.0.0.125:44401/dev/f4fe91fd-dfe2-07ed-ffff-ffffd91a1d9a"
    let mediaServerBase = "http://10.0.0.125:44402/uuid-cca7c79e-ae0d-f745-afa4-e45f01e9f574"
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Mock(url: URL(string: "\(openHomeBase)/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.openHomeRendererXML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Credentials/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.credentials1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Info/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.info1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/OAuth/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.oauth1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Playlist/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.playlist1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Product/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.product1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Time/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.timeXML1.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Transport/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.transportXML1.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/Volume/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.volume1XML.data]).register()
        Mock(url: URL(string: "\(openHomeBase)/svc/av-openhome-org/OAuth/desc.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.oauth1XML.data]).register()
        
        Mock(url: URL(string: "\(mediaServerBase)/description.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.mediaServerXML.data]).register()
        Mock(url: URL(string: "\(mediaServerBase)/urn-schemas-upnp-org-service-ConnectionManager-1.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.connectionManager1XML.data]).register()
        Mock(url: URL(string: "\(mediaServerBase)/urn-schemas-upnp-org-service-ContentDirectory-1.xml")!, contentType: .xml, statusCode: 200, data: [.get : MockedData.contentDirectory1XML.data]).register()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cancellables.removeAll()
    }
    
    @MainActor
    func testReanimateOpenHomePlayer() async throws {
        let playerDescription = UPnPDeviceDescription(uuid: "uuid:f4fe91fd-dfe2-07ed-ffff-ffffd91a1d9a",
                                                      deviceId: "urn:linn-co-uk:device:Source:1",
                                                      deviceType: "urn:linn-co-uk:device:Source:1",
                                                      url: URL(string: "\(openHomeBase)/desc.xml")!,
                                                      lastSeen: Date())
        
        let noDeviceAddedExpectation = XCTestExpectation(description: "No device is being added")
        noDeviceAddedExpectation.isInverted = true
        UPnPRegistry.shared.deviceAdded
            .sink { _ in
                noDeviceAddedExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        let player = await UPnPDevice.reanimateDeep(upnpDeviceDescription: playerDescription)
        XCTAssertNotNil(player, "player not loaded")
        XCTAssertEqual(player!.services.count, 8)
        XCTAssertNotNil(player!.openHomeCredentials1Service)
        XCTAssertNotNil(player!.openHomeInfo1Service)
        XCTAssertNotNil(player!.openHomeOAuth1Service)
        XCTAssertNotNil(player!.openHomePlaylist1Service)
        XCTAssertNotNil(player!.openHomeProduct1Service)
        XCTAssertNotNil(player!.openHomeTime1Service)
        XCTAssertNotNil(player!.openHomeTransport1Service)
        XCTAssertNotNil(player!.openHomeVolume1Service)
        
        await fulfillment(of: [noDeviceAddedExpectation], timeout: 0.3)
    }
    
    @MainActor
    func testReanimateMediaServer() async throws {
        let noDeviceAddedExpectation = XCTestExpectation(description: "No device is being added")
        noDeviceAddedExpectation.isInverted = true
        UPnPRegistry.shared.deviceAdded
            .sink { _ in
                noDeviceAddedExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        let mediaServerDescription = UPnPDeviceDescription(uuid: "uuid:cca7c79e-ae0d-f745-afa4-e45f01e9f574",
                                                      deviceId: "urn:schemas-upnp-org:device:MediaServer:1",
                                                      deviceType: "urn:schemas-upnp-org:device:MediaServer:1",
                                                      url: URL(string: "\(mediaServerBase)/description.xml")!,
                                                      lastSeen: Date())

        let mediaServer = await UPnPDevice.reanimateDeep(upnpDeviceDescription: mediaServerDescription)
        XCTAssertNotNil(mediaServer, "mediaServer not loaded")
        XCTAssertEqual(mediaServer!.services.count, 2)
        XCTAssertNotNil(mediaServer!.contentDirectory1Service)
        XCTAssertNotNil(mediaServer!.connectionManager1Service)

        await fulfillment(of: [noDeviceAddedExpectation], timeout: 0.3)
    }
}
