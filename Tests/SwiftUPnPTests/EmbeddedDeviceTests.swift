//
// EmbeddedDeviceTests.swift
//
// Devices like Sonos expose their MediaRenderer as an *embedded* device (deviceList) of a
// vendor-specific root device (ZonePlayer), so AVTransport/RenderingControl never appear in the
// root serviceList. These tests cover parsing of deviceList and service collection across the
// whole device tree.
//

import XCTest
@testable import SwiftUPnP
import XMLCoder

final class EmbeddedDeviceTests: XCTestCase {
    private var sonosDescription: Data {
        Bundle.module.url(forResource: "SonosZonePlayerDevice", withExtension: "xml")!.data
    }

    private func decodeSonos() throws -> UPnPDeviceDefinition {
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = false
        return try decoder.decode(UPnPDeviceDefinition.self, from: sonosDescription)
    }

    func testDeviceListIsParsed() throws {
        let definition = try decodeSonos()

        XCTAssertEqual(definition.device.deviceType, "urn:schemas-upnp-org:device:ZonePlayer:1")
        let embedded = definition.device.deviceList?.device ?? []
        XCTAssertEqual(embedded.map(\.deviceType), ["urn:schemas-upnp-org:device:MediaServer:1",
                                                    "urn:schemas-upnp-org:device:MediaRenderer:1"])
        XCTAssertEqual(definition.device.allDevices.count, 3)
    }

    func testAllServicesIncludesEmbeddedRendererServices() throws {
        let definition = try decodeSonos()

        // Not on the root device…
        XCTAssertNil(definition.device.serviceList?.service.first {
            $0.serviceType == "urn:schemas-upnp-org:service:AVTransport:1"
        })
        // …but reachable through the device tree.
        let avTransport = definition.device.allServices.first {
            $0.serviceType == "urn:schemas-upnp-org:service:AVTransport:1"
        }
        XCTAssertEqual(avTransport?.controlURL, "/MediaRenderer/AVTransport/Control")
        XCTAssertNotNil(definition.device.allServices.first {
            $0.serviceType == "urn:schemas-upnp-org:service:RenderingControl:1"
        })
    }

    func testDuplicateServiceTypesKeepTheirOwnUrls() throws {
        let definition = try decodeSonos()

        // ConnectionManager exists on both embedded devices; each keeps its own controlURL.
        let connectionManagers = definition.device.allServices.filter {
            $0.serviceType == "urn:schemas-upnp-org:service:ConnectionManager:1"
        }
        XCTAssertEqual(connectionManagers.map(\.controlURL), ["/MediaServer/ConnectionManager/Control",
                                                              "/MediaRenderer/ConnectionManager/Control"])
    }

    func testSonosRoomNameIsExposed() throws {
        let definition = try decodeSonos()

        XCTAssertEqual(definition.device.roomName, "Sala de estar")
    }

    func testDeviceWithoutDeviceListStillDecodes() throws {
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = false
        let definition = try decoder.decode(UPnPDeviceDefinition.self,
                                            from: Bundle.module.url(forResource: "MediaServerDevice", withExtension: "xml")!.data)

        XCTAssertNil(definition.device.deviceList)
        XCTAssertNil(definition.device.roomName)
        XCTAssertEqual(definition.device.allServices.count, definition.device.serviceList?.service.count)
    }
}
