//
// Product: SwiftUPnP
// Package: SwiftUPnPTests
//
// Tests for the broadcaster that took the place of Combine's subjects: one source of values, any
// number of readers, each of whom reads at their own pace.
//

import XCTest
@testable import SwiftUPnP

final class AsyncBroadcasterTests: XCTestCase {
    /// What a subject did: every listener sees every value, rather than the listeners taking
    /// values away from one another.
    func testEveryListenerReceivesEveryValue() async throws {
        let broadcaster = AsyncBroadcaster<Int>()

        let first = collect(3, from: broadcaster.stream)
        let second = collect(3, from: broadcaster.stream)
        try await waitUntil { broadcaster.hasListeners }

        for value in 1...3 {
            broadcaster.send(value)
        }

        let firstValues = await first.value
        let secondValues = await second.value
        XCTAssertEqual(firstValues, [1, 2, 3])
        XCTAssertEqual(secondValues, [1, 2, 3])
    }

    /// Values sent before a listener starts are gone: a state change reports what a device is
    /// doing now, and a listener that wasn't there has no claim to the past.
    func testAListenerOnlySeesWhatIsSentAfterItStarts() async throws {
        let broadcaster = AsyncBroadcaster<Int>()

        broadcaster.send(1)
        let received = collect(1, from: broadcaster.stream)
        try await waitUntil { broadcaster.hasListeners }

        broadcaster.send(2)

        let values = await received.value
        XCTAssertEqual(values, [2], "a value from before the listener started was delivered")
    }

    /// A listener that is slow may not hold up the thread an event arrived on, nor the listeners
    /// that are keeping up.
    func testASlowListenerDoesNotHoldUpAnother() async throws {
        let broadcaster = AsyncBroadcaster<Int>()

        let idleStream = broadcaster.stream
        let reading = collect(100, from: broadcaster.stream)
        try await waitUntil { broadcaster.hasListeners }

        for value in 1...100 {
            broadcaster.send(value)
        }

        let values = await reading.value
        XCTAssertEqual(values.count, 100)
        // Held to the end, so the stream that was never read stays a listener throughout.
        XCTAssertNotNil(idleStream)
    }

    func testAListenerThatStopsIsDropped() async throws {
        let broadcaster = AsyncBroadcaster<Int>()

        let reading = collect(1, from: broadcaster.stream)
        try await waitUntil { broadcaster.hasListeners }

        broadcaster.send(1)
        _ = await reading.value

        try await waitUntil { broadcaster.hasListeners == false }
        XCTAssertFalse(broadcaster.hasListeners)
    }

    func testFinishingEndsTheStreamsThatAreBeingRead() async throws {
        let broadcaster = AsyncBroadcaster<Int>()

        // Asks for more than will ever be sent, so it only ends because the broadcaster finished.
        let reading = collect(10, from: broadcaster.stream)
        try await waitUntil { broadcaster.hasListeners }

        broadcaster.send(1)
        broadcaster.finish()

        let values = await reading.value
        XCTAssertEqual(values, [1])
    }

    func testAStreamStartedAfterFinishingIsImmediatelyDone() async throws {
        let broadcaster = AsyncBroadcaster<Int>()
        broadcaster.finish()

        var values = [Int]()
        for await value in broadcaster.stream {
            values.append(value)
        }

        XCTAssertEqual(values, [])
    }

    /// Reads up to `count` values, and stops reading as soon as it has them.
    private func collect<Element: Sendable>(_ count: Int, from stream: AsyncStream<Element>) -> Task<[Element], Never> {
        Task {
            var values = [Element]()
            for await value in stream {
                values.append(value)
                if values.count == count { break }
            }
            return values
        }
    }

    private func waitUntil(_ condition: @Sendable () -> Bool, within timeout: TimeInterval = 5) async throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("The condition was not met within \(timeout) seconds")
    }
}
