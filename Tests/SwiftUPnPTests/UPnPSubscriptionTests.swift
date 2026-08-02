//
// Product: SwiftUPnP
// Package: SwiftUPnPTests
//
// Tests for keeping an event subscription alive. State changes are the only thing that keeps a
// player's status up to date, so a subscription that is not restored after a failure means no more
// updates at all until the app is restarted.
//

import XCTest
import Swifter
import Mocker
@testable import SwiftUPnP

/// Stands in for the event subscription endpoint of a device, so subscribing can be tested without
/// a device on the network. Answers whatever it is told to answer, and counts the attempts.
private final class FakeEventEndpoint {
    enum Answer {
        /// A subscription is granted, with the given value for the TIMEOUT header (nil to leave the
        /// header out altogether, which devices do).
        case granted(timeout: String?)
        /// Success, but without the subscription id that is needed to recognize events as ours.
        case grantedWithoutSubscriptionId
        case refused(statusCode: Int)
    }

    private let server = HttpServer()
    private let lock = NSLock()
    private var _answer = Answer.granted(timeout: "Second-120")
    private var _subscribeCount = 0
    private var _unsubscribeCount = 0
    let port: UInt16

    var answer: Answer {
        get { lock.lock(); defer { lock.unlock() }; return _answer }
        set { lock.lock(); _answer = newValue; lock.unlock() }
    }
    var subscribeCount: Int {
        lock.lock(); defer { lock.unlock() }; return _subscribeCount
    }
    var unsubscribeCount: Int {
        lock.lock(); defer { lock.unlock() }; return _unsubscribeCount
    }

    init() throws {
        port = IPHelper.freePortFromRange(range: 52000..<52099)
        server["/event"] = { [weak self] request in

            guard let self else { return .internalServerError(.text("gone")) }

            switch request.method.lowercased() {
            case "subscribe":
                self.lock.lock()
                self._subscribeCount += 1
                let answer = self._answer
                self.lock.unlock()

                switch answer {
                case let .granted(timeout):
                    var headers = ["SID": "uuid:subscription-\(self.subscribeCount)"]
                    if let timeout {
                        headers["TIMEOUT"] = timeout
                    }
                    return .raw(200, "OK", headers, nil)
                case .grantedWithoutSubscriptionId:
                    return .raw(200, "OK", ["TIMEOUT": "Second-120"], nil)
                case let .refused(statusCode):
                    return .raw(statusCode, "Refused", nil, nil)
                }
            case "unsubscribe":
                self.lock.lock()
                self._unsubscribeCount += 1
                self.lock.unlock()

                return .raw(200, "OK", nil, nil)
            default:
                return .internalServerError(.text("unexpected method \(request.method)"))
            }
        }
        try startListening()
    }

    /// Make the device reachable, or unreachable, so a request that fails outright can be tested
    /// next to one that is answered with a refusal.
    func startListening() throws {
        try server.start(port)
    }

    func stopListening() {
        server.stop()
    }
}

final class UPnPSubscriptionTests: XCTestCase {
    private var endpoint: FakeEventEndpoint!
    private var device: UPnPDevice!
    private var service: UPnPService!

    override func setUpWithError() throws {
        endpoint = try FakeEventEndpoint()

        let base = "http://127.0.0.1:\(endpoint.port)"
        // These tests talk to a server of their own rather than to mocked responses, and other tests
        // in this package leave the mocking url protocol registered, which by default takes over
        // every request that isn't explicitly ignored.
        Mocker.ignore(URL(string: "\(base)/event")!)

        device = UPnPDevice(upnpDeviceDescription: UPnPDeviceDescription(uuid: "uuid:test-device",
                                                                        deviceId: "urn:test:device:Source:1",
                                                                        deviceType: "urn:test:device:Source:1",
                                                                        url: URL(string: "\(base)/desc.xml")!,
                                                                        lastSeen: Date()))
        service = UPnPService(device: device,
                              controlUrl: URL(string: "\(base)/control")!,
                              scpdUrl: URL(string: "\(base)/desc.xml")!,
                              eventUrl: URL(string: "\(base)/event")!,
                              serviceType: "urn:test:service:Time:1",
                              serviceId: "urn:test:serviceId:Time",
                              eventPublisher: nil,
                              eventCallbackUrl: URL(string: "\(base)/callback")!)
    }

    override func tearDown() async throws {
        await service?.unsubscribeFromEvents()
        service = nil
        device = nil
        endpoint.stopListening()
        endpoint = nil
    }

    /// A single request that doesn't arrive - a player that is rebooting, a network hiccup - used to
    /// leave the service in a state from which it never subscribed again, which means no more status
    /// updates for the rest of the session.
    func testASubscriptionIsEstablishedAfterAnUnreachablePlayerReturns() async throws {
        endpoint.stopListening()

        await service.subscribeToEvents()
        try await Task.sleep(nanoseconds: 500_000_000)
        let statusWhileUnreachable = await service.subscriptionStatus
        XCTAssertNotEqual(statusWhileUnreachable, .subscribed)

        try endpoint.startListening()

        try await waitUntilSubscribed()
    }

    /// A device that refuses to be subscribed to used to be retried without any pause, endlessly.
    func testARefusedSubscriptionIsRetriedWithAPause() async throws {
        endpoint.answer = .refused(statusCode: 500)

        await service.subscribeToEvents()
        try await Task.sleep(nanoseconds: 2_500_000_000)

        XCTAssertGreaterThanOrEqual(endpoint.subscribeCount, 2, "the subscription was not retried")
        XCTAssertLessThanOrEqual(endpoint.subscribeCount, 4, "the subscription was retried without pausing")
    }

    /// Without a subscription id events can't be recognized as ours, so this is a failed attempt
    /// even though the device reported success. It used to be treated as success, after which the
    /// service was stuck: it neither received events nor ever subscribed again.
    func testSuccessWithoutASubscriptionIdIsNotAcceptedAsSubscribed() async throws {
        endpoint.answer = .grantedWithoutSubscriptionId

        await service.subscribeToEvents()
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let status = await service.subscriptionStatus
        XCTAssertNotEqual(status, .subscribed)
        XCTAssertGreaterThanOrEqual(endpoint.subscribeCount, 2, "the subscription was not retried")

        endpoint.answer = .granted(timeout: "Second-120")
        try await waitUntilSubscribed()
    }

    /// A device is allowed to answer with a timeout of "infinite", and some answer with no timeout
    /// at all. Neither may stand in the way of a working subscription.
    func testATimeoutThatIsNotANumberOfSecondsIsAccepted() async throws {
        endpoint.answer = .granted(timeout: "Second-infinite")

        await service.subscribeToEvents()
        try await waitUntilSubscribed()
    }

    func testAMissingTimeoutIsAccepted() async throws {
        endpoint.answer = .granted(timeout: nil)

        await service.subscribeToEvents()
        try await waitUntilSubscribed()
    }

    /// What the watchdog in a status monitor uses to tell a subscription that stopped delivering
    /// from a player that has nothing to report.
    func testSilenceIsOnlyReportedWhileSubscribed() async throws {
        XCTAssertNil(service.eventSilence, "silence is meaningless without a subscription")

        await service.subscribeToEvents()
        try await waitUntilSubscribed()

        XCTAssertNotNil(service.eventSilence)
        XCTAssertNil(service.lastEventReceived, "no event was sent")

        await service.unsubscribeFromEvents()
        XCTAssertNil(service.eventSilence)
    }

    func testUnsubscribingStopsMaintainingTheSubscription() async throws {
        await service.subscribeToEvents()
        try await waitUntilSubscribed()

        await service.unsubscribeFromEvents()
        XCTAssertEqual(endpoint.unsubscribeCount, 1)

        // Renewals happen well before the subscription would expire, so a maintenance loop that
        // kept running would show up as further attempts.
        endpoint.answer = .refused(statusCode: 500)
        let attemptsAtUnsubscribe = endpoint.subscribeCount
        try await Task.sleep(nanoseconds: 2_000_000_000)

        XCTAssertEqual(endpoint.subscribeCount, attemptsAtUnsubscribe)
        let status = await service.subscriptionStatus
        XCTAssertEqual(status, .unsubscribed)
    }

    /// Renewals are far apart, so a maintenance loop that holds on to its service between them keeps
    /// a player that is no longer used alive, and keeps it talking to the network.
    func testAServiceIsNotKeptAliveByItsSubscription() async throws {
        await service.subscribeToEvents()
        try await waitUntilSubscribed()

        weak var releasedService = service
        service = nil

        let deadline = Date(timeIntervalSinceNow: 3)
        while releasedService != nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        XCTAssertNil(releasedService, "the subscription kept the service alive")
    }

    private func waitUntilSubscribed(timeout: TimeInterval = 10) async throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while Date() < deadline {
            if await service.subscriptionStatus == .subscribed { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        XCTFail("No subscription was established within \(timeout) seconds")
    }
}
