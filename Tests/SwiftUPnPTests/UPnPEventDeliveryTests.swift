//
// Product: SwiftUPnP
// Package: SwiftUPnPTests
//
// Tests that a notification posted by a device reaches the state changes of the service it belongs
// to. This is the path that used to run through Combine, and the one thing a UPnP controller cannot
// do without: without it a player's status is whatever it was when the app started.
//

import XCTest
import Mocker
@testable import SwiftUPnP

// Devices and the services they own keep their state on the main actor.
@MainActor
final class UPnPEventDeliveryTests: XCTestCase {
    private var endpoint: FakeSubscriptionEndpoint!
    private var events: AsyncBroadcaster<UPnPEvent>!
    private var device: UPnPDevice!
    private var service: OpenHomeTime1Service!

    override func setUp() async throws {
        endpoint = try await FakeSubscriptionEndpoint()
        events = AsyncBroadcaster<UPnPEvent>()

        let base = "http://127.0.0.1:\(endpoint.port)"
        // These tests talk to a server of their own rather than to mocked responses, and other
        // tests in this package leave the mocking url protocol registered.
        Mocker.ignore(URL(string: "\(base)/event")!)

        device = UPnPDevice(upnpDeviceDescription: UPnPDeviceDescription(uuid: "uuid:test-device",
                                                                        deviceId: "urn:test:device:Source:1",
                                                                        deviceType: "urn:test:device:Source:1",
                                                                        url: URL(string: "\(base)/desc.xml")!,
                                                                        lastSeen: Date()))
        service = OpenHomeTime1Service(device: device,
                                       controlUrl: URL(string: "\(base)/control")!,
                                       scpdUrl: URL(string: "\(base)/desc.xml")!,
                                       eventUrl: URL(string: "\(base)/event")!,
                                       serviceType: "urn:av-openhome-org:service:Time:1",
                                       serviceId: "urn:av-openhome-org:serviceId:Time",
                                       events: events,
                                       eventCallbackUrl: URL(string: "\(base)/callback")!)
    }

    override func tearDown() async throws {
        await service?.unsubscribeFromEvents()
        service = nil
        device = nil
        events = nil
        endpoint.stopListening()
        endpoint = nil
    }

    func testANotificationArrivesAsAParsedStateChange() async throws {
        let subscriptionId = try await subscribe()

        // Taken before anything is sent: accessing the stream is what registers the listener,
        // and a listener only sees what is sent after it starts.
        let states = listen(to: service.stateChangeStream)

        events.send(UPnPEvent(subscriptionId: subscriptionId, body: propertySet(trackCount: 12, seconds: 34)))

        let received = await states.value
        let state = try XCTUnwrap(received)
        XCTAssertEqual(state.trackCount, 12)
        XCTAssertEqual(state.seconds, 34)
    }

    /// A notification carries no service identity, only the subscription it belongs to: every
    /// service sees every notification and has to recognize its own.
    func testANotificationForAnotherSubscriptionIsIgnored() async throws {
        let subscriptionId = try await subscribe()

        let states = listen(to: service.stateChangeStream)

        events.send(UPnPEvent(subscriptionId: "uuid:somebody-else", body: propertySet(trackCount: 99, seconds: 99)))
        events.send(UPnPEvent(subscriptionId: subscriptionId, body: propertySet(trackCount: 1, seconds: 2)))

        let received = await states.value
        let state = try XCTUnwrap(received)
        XCTAssertEqual(state.trackCount, 1, "a notification for another subscription was reported")
        XCTAssertEqual(state.seconds, 2)
    }

    /// Each reader gets its own stream, so a second listener doesn't take state changes away from
    /// the first.
    func testTwoListenersBothReceiveTheStateChange() async throws {
        let subscriptionId = try await subscribe()

        let first = listen(to: service.stateChangeStream)
        let second = listen(to: service.stateChangeStream)

        events.send(UPnPEvent(subscriptionId: subscriptionId, body: propertySet(trackCount: 7, seconds: 8)))

        let firstReceived = await first.value
        let secondReceived = await second.value
        let firstState = try XCTUnwrap(firstReceived)
        let secondState = try XCTUnwrap(secondReceived)
        XCTAssertEqual(firstState.trackCount, 7)
        XCTAssertEqual(secondState.trackCount, 7)
    }

    /// What a watchdog uses to tell a subscription that stopped delivering from a player with
    /// nothing to report. It has to keep working whether or not anybody reads the state changes.
    func testAnArrivingNotificationIsRecordedWithoutAnybodyListening() async throws {
        let subscriptionId = try await subscribe()
        XCTAssertNil(service.lastEventReceived, "nothing was sent yet")

        events.send(UPnPEvent(subscriptionId: subscriptionId, body: propertySet(trackCount: 3, seconds: 4)))

        try await waitUntil { self.service.lastEventReceived != nil }
        XCTAssertNotNil(service.lastEventReceived)
    }

    /// Readers hold the service weakly, the way the Combine publisher did: a player that is no
    /// longer used must not be kept alive by somebody who is still listening for its state.
    func testAListenerDoesNotKeepTheServiceAlive() async throws {
        _ = try await subscribe()

        let listening = Task { [stream = service.stateChangeStream] in
            for await _ in stream {}
        }
        try await waitUntil { self.events.hasListeners }

        weak let releasedService = service
        await service.unsubscribeFromEvents()
        service = nil

        try await waitUntil { releasedService == nil }
        XCTAssertNil(releasedService, "a listener kept the service alive")

        listening.cancel()
    }

    // MARK: - Helpers

    /// Subscribe and report the subscription id the endpoint granted, which is what the events of
    /// this service are marked with.
    private func subscribe() async throws -> String {
        await service.subscribeToEvents()

        try await waitUntil { self.service.subscriptionStatus == .subscribed }
        return endpoint.lastGrantedSubscriptionId
    }

    /// Start reading a stream and report its first state change, or nil when none arrives in time.
    /// The stream is taken by the caller, so that it is listening before anything is sent.
    private nonisolated func listen(to stream: AsyncStream<OpenHomeTime1Service.State>,
                                    within timeout: TimeInterval = 5) -> Task<OpenHomeTime1Service.State?, Never> {
        Task {
            await withTaskGroup(of: OpenHomeTime1Service.State?.self) { group in
                group.addTask {
                    for await state in stream { return state }
                    return nil
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    return nil
                }

                let first = await group.next() ?? nil
                group.cancelAll()
                return first
            }
        }
    }

    private func propertySet(trackCount: UInt32, seconds: UInt32) -> Data {
        Data("""
        <?xml version="1.0"?>
        <e:propertyset xmlns:e="urn:schemas-upnp-org:event-1-0">
            <e:property><TrackCount>\(trackCount)</TrackCount></e:property>
            <e:property><Seconds>\(seconds)</Seconds></e:property>
        </e:propertyset>
        """.utf8)
    }

    private func waitUntil(_ condition: () -> Bool, within timeout: TimeInterval = 5) async throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTFail("The condition was not met within \(timeout) seconds")
    }
}

/// Grants every subscription it is asked for, and remembers the id it handed out last, so a test
/// can mark its events with the id the service is actually filtering on.
private final class FakeSubscriptionEndpoint: @unchecked Sendable {
    private let server = HTTPServer()
    private let lock = NSLock()
    private var _lastGrantedSubscriptionId = ""
    private var _subscribeCount = 0
    let port: UInt16

    var lastGrantedSubscriptionId: String {
        lock.lock(); defer { lock.unlock() }; return _lastGrantedSubscriptionId
    }

    init() async throws {
        port = IPHelper.freePortFromRange(range: 52100..<52199)
        let lock = self.lock
        server.handler = { [weak self] request in
            guard let self else { return .internalServerError("gone") }
            guard request.path == "/event" else { return .notFound() }

            switch request.method {
            case "SUBSCRIBE":
                lock.lock()
                self._subscribeCount += 1
                let subscriptionId = "uuid:subscription-\(self._subscribeCount)"
                self._lastGrantedSubscriptionId = subscriptionId
                lock.unlock()

                return .status(200, "OK", headers: ["SID": subscriptionId, "TIMEOUT": "Second-120"])
            case "UNSUBSCRIBE":
                return .status(200, "OK")
            default:
                return .internalServerError("unexpected method \(request.method)")
            }
        }
        try await server.start(port: port)
    }

    func stopListening() {
        server.stop()
    }
}
