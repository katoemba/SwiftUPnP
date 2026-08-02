//
// Product: SwiftUPnP
// Package: SwiftUPnPTests
//
// Tests for the http server that events are received on. Devices phrase their notifications in
// whatever way their firmware author saw fit, and a notification that isn't understood is a state
// change that never arrives.
//

import XCTest
import Mocker
@testable import SwiftUPnP

final class HTTPRequestParserTests: XCTestCase {
    /// `head` is the request line and its headers, without the empty line that ends them: that is
    /// added here, because a trailing empty line in a literal is too easy to lose.
    private func buffer(_ head: String, body: String = "") -> Data {
        Data((crlf(head) + "\r\n\r\n" + body).utf8)
    }

    /// For bodies that are made up of lines of their own, like chunks.
    private func crlf(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: "\r\n")
    }

    /// The shape of every event notification: a method that isn't part of http, the subscription id
    /// in a header, and the state change in the body.
    func testANotificationIsParsed() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        HOST: 192.168.1.10:51000
        CONTENT-TYPE: text/xml
        SID: uuid:subscription-1
        CONTENT-LENGTH: 11
        """, body: "hello there")

        guard case let .request(request, keepAlive) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertEqual(request.method, "NOTIFY")
        XCTAssertEqual(request.path, "/Event/abc")
        XCTAssertEqual(request.header("SID"), "uuid:subscription-1")
        XCTAssertEqual(String(data: request.body, encoding: .utf8), "hello there")
        XCTAssertTrue(keepAlive, "http/1.1 holds the connection open unless it says otherwise")
        XCTAssertTrue(data.isEmpty, "the request was not consumed")
    }

    func testTheMethodAndHeaderNamesAreMatchedRegardlessOfCase() throws {
        var data = buffer("""
        notify /Event/abc HTTP/1.1
        Sid: uuid:subscription-1
        Content-Length: 0
        """)

        guard case let .request(request, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertEqual(request.method, "NOTIFY")
        XCTAssertEqual(request.header("sid"), "uuid:subscription-1")
    }

    /// A device is free to address us by the full url it subscribed with rather than by path only.
    func testAnAbsoluteRequestTargetIsReducedToItsPath() throws {
        var data = buffer("""
        NOTIFY http://192.168.1.10:51000/Event/abc HTTP/1.1
        Content-Length: 0
        """)

        guard case let .request(request, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertEqual(request.path, "/Event/abc")
    }

    func testABodyWithoutAContentLengthIsEmpty() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        SID: uuid:subscription-1
        """)

        guard case let .request(request, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertTrue(request.body.isEmpty)
    }

    /// Devices that don't know the size of the state change up front send it in chunks.
    func testAChunkedBodyIsAssembled() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        Transfer-Encoding: chunked
        """, body: crlf("5\nhello\n6\n there\n0\n\n"))

        guard case let .request(request, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertEqual(String(data: request.body, encoding: .utf8), "hello there")
        XCTAssertTrue(data.isEmpty, "the request was not consumed")
    }

    func testAChunkedBodyWithTrailersIsAssembled() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        Transfer-Encoding: chunked
        """, body: crlf("b;extension=ignored\nhello there\n0\nX-Trailer: ignored\n\n"))

        guard case let .request(request, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }

        XCTAssertEqual(String(data: request.body, encoding: .utf8), "hello there")
        XCTAssertTrue(data.isEmpty, "the request was not consumed")
    }

    /// Nothing guarantees that a notification arrives in one piece, and a body that is still on its
    /// way may not be handed over half finished.
    func testARequestIsOnlyParsedOnceItHasFullyArrived() throws {
        let complete = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        SID: uuid:subscription-1
        Content-Length: 11
        """, body: "hello there")

        for length in 1..<complete.count {
            var partial = complete.prefix(length)
            guard case .incomplete = HTTPRequestParser.parse(&partial) else {
                return XCTFail("a request of \(length) out of \(complete.count) bytes was parsed")
            }
            XCTAssertEqual(partial.count, length, "an incomplete request was consumed")
        }

        var data = complete
        guard case .request = HTTPRequestParser.parse(&data) else {
            return XCTFail("the completed notification was not parsed")
        }
    }

    func testAChunkedBodyIsOnlyParsedOnceItHasFullyArrived() throws {
        let complete = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        Transfer-Encoding: chunked
        """, body: crlf("5\nhello\n0\n\n"))

        for length in 1..<complete.count {
            var partial = complete.prefix(length)
            guard case .incomplete = HTTPRequestParser.parse(&partial) else {
                return XCTFail("a request of \(length) out of \(complete.count) bytes was parsed")
            }
        }
    }

    /// A device that keeps its connection open can have a second notification underway before the
    /// first was answered.
    func testTwoNotificationsThatArriveTogetherAreBothParsed() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        SID: uuid:one
        Content-Length: 5
        """, body: "first") + buffer("""
        NOTIFY /Event/abc HTTP/1.1
        SID: uuid:two
        Content-Length: 6
        """, body: "second")

        guard case let .request(first, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the first notification was not parsed")
        }
        XCTAssertEqual(first.header("SID"), "uuid:one")
        XCTAssertEqual(String(data: first.body, encoding: .utf8), "first")

        guard case let .request(second, _) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the second notification was not parsed")
        }
        XCTAssertEqual(second.header("SID"), "uuid:two")
        XCTAssertEqual(String(data: second.body, encoding: .utf8), "second")
        XCTAssertTrue(data.isEmpty)
    }

    func testAConnectionIsNotHeldOpenWhenTheDeviceAsksForItToBeClosed() throws {
        var data = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        Connection: close
        Content-Length: 0
        """)

        guard case let .request(_, keepAlive) = HTTPRequestParser.parse(&data) else {
            return XCTFail("the notification was not parsed")
        }
        XCTAssertFalse(keepAlive)
    }

    func testAnHTTP10ConnectionIsOnlyHeldOpenWhenTheDeviceAsksForIt() throws {
        var closing = buffer("""
        NOTIFY /Event/abc HTTP/1.0
        Content-Length: 0
        """)
        guard case let .request(_, closingKeepAlive) = HTTPRequestParser.parse(&closing) else {
            return XCTFail("the notification was not parsed")
        }
        XCTAssertFalse(closingKeepAlive)

        var keeping = buffer("""
        NOTIFY /Event/abc HTTP/1.0
        Connection: keep-alive
        Content-Length: 0
        """)
        guard case let .request(_, keepingKeepAlive) = HTTPRequestParser.parse(&keeping) else {
            return XCTFail("the notification was not parsed")
        }
        XCTAssertTrue(keepingKeepAlive)
    }

    func testAnUnusableRequestIsReportedAsMalformed() throws {
        var noTarget = buffer("NOTIFY")
        guard case .malformed = HTTPRequestParser.parse(&noTarget) else {
            return XCTFail("a request line without a target was accepted")
        }

        var noColon = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        this is not a header
        """)
        guard case .malformed = HTTPRequestParser.parse(&noColon) else {
            return XCTFail("a header line without a colon was accepted")
        }

        var notANumber = buffer("""
        NOTIFY /Event/abc HTTP/1.1
        Content-Length: some
        """)
        guard case .malformed = HTTPRequestParser.parse(&notANumber) else {
            return XCTFail("a content length that is not a number was accepted")
        }
    }
}

final class HTTPServerTests: XCTestCase {
    private var server: HTTPServer!
    private var port: UInt16 = 0

    override func setUp() async throws {
        server = HTTPServer()
        port = IPHelper.freePortFromRange(range: 53000..<53099)
    }

    override func tearDown() async throws {
        server?.stop()
        server = nil
    }

    /// Send a request the way a device does, over a connection of its own.
    @discardableResult
    private func send(method: String, path: String, headers: [String: String] = [:], body: Data = Data()) async throws -> HTTPURLResponse {
        let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
        // Other tests in this package leave the mocking url protocol registered, which by default
        // takes over every request that isn't explicitly ignored.
        Mocker.ignore(url)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body.isEmpty ? nil : body
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        // A session of its own, so that no request here is sent over a pooled connection that a
        // previous one left behind: a server that was restarted in between has closed it.
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }

        let (_, response) = try await session.data(for: request)
        return try XCTUnwrap(response as? HTTPURLResponse)
    }

    func testANotificationIsHandedToTheHandler() async throws {
        let received = Received()
        server.handler = { request in
            received.append(request)
            return .ok()
        }
        try await server.start(port: port)

        let response = try await send(method: "NOTIFY",
                                      path: "/Event/abc",
                                      headers: ["SID": "uuid:subscription-1"],
                                      body: Data("<propertyset/>".utf8))

        XCTAssertEqual(response.statusCode, 200)
        let requests = received.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.method, "NOTIFY")
        XCTAssertEqual(requests.first?.path, "/Event/abc")
        XCTAssertEqual(requests.first?.header("SID"), "uuid:subscription-1")
        XCTAssertEqual(requests.first.map { String(data: $0.body, encoding: .utf8) }, "<propertyset/>")
    }

    /// The status and headers a handler answers with are what a device gets to see, which is what a
    /// subscription is built on.
    func testTheAnswerOfTheHandlerIsSentBack() async throws {
        server.handler = { _ in
            .status(200, "OK", headers: ["SID": "uuid:subscription-1", "TIMEOUT": "Second-300"])
        }
        try await server.start(port: port)

        let response = try await send(method: "SUBSCRIBE", path: "/Event/abc")

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.value(forHTTPHeaderField: "SID"), "uuid:subscription-1")
        XCTAssertEqual(response.value(forHTTPHeaderField: "TIMEOUT"), "Second-300")
    }

    /// Devices reuse their connection between notifications, and a second notification over a
    /// connection that was already answered once used to be where a server stopped keeping up.
    func testNotificationsOverOneConnectionAreAllHandled() async throws {
        let received = Received()
        server.handler = { request in
            received.append(request)
            return .ok()
        }
        try await server.start(port: port)

        // URLSession keeps its connection to a host alive between requests of the same session.
        let session = URLSession(configuration: .default)
        let url = URL(string: "http://127.0.0.1:\(port)/Event/abc")!
        Mocker.ignore(url)

        for index in 0..<3 {
            var request = URLRequest(url: url)
            request.httpMethod = "NOTIFY"
            request.setValue("uuid:subscription-\(index)", forHTTPHeaderField: "SID")
            request.httpBody = Data("change \(index)".utf8)
            _ = try await session.data(for: request)
        }

        XCTAssertEqual(received.requests.map { $0.header("SID") },
                       ["uuid:subscription-0", "uuid:subscription-1", "uuid:subscription-2"])
    }

    func testARequestForAnotherPathIsAnsweredByTheHandler() async throws {
        server.handler = { request in
            request.path == "/Event/abc" ? .ok() : .notFound()
        }
        try await server.start(port: port)

        let response = try await send(method: "NOTIFY", path: "/somewhere/else")
        XCTAssertEqual(response.statusCode, 404)
    }

    func testTheServerReportsWhetherItIsListening() async throws {
        XCTAssertFalse(server.isRunning)

        try await server.start(port: port)
        XCTAssertTrue(server.isRunning)
        XCTAssertEqual(server.port, port)

        server.stop()
        XCTAssertFalse(server.isRunning)
        XCTAssertEqual(server.port, 0)
    }

    /// The event delivery path is rebuilt by restarting the server on the port it was already using,
    /// which fails if the previous socket isn't released for reuse right away.
    func testTheServerCanBeRestartedOnTheSamePort() async throws {
        server.handler = { _ in .ok() }

        for _ in 0..<3 {
            try await server.start(port: port)
            let response = try await send(method: "NOTIFY", path: "/Event/abc")
            XCTAssertEqual(response.statusCode, 200)
            server.stop()
        }
    }

    /// A port that is taken has to be reported, so another one can be tried. A server that silently
    /// shares the port with whoever holds it would receive only part of the notifications.
    func testListeningOnATakenPortFails() async throws {
        try await server.start(port: port)

        let second = HTTPServer()
        defer { second.stop() }

        do {
            try await second.start(port: port)
            XCTFail("two servers ended up listening on port \(self.port)")
        }
        catch {
            XCTAssertFalse(second.isRunning)
        }
    }

    /// Collects what the handler was given, from whatever queue it was called on.
    private final class Received {
        private let lock = NSLock()
        private var _requests = [HTTPServerRequest]()

        func append(_ request: HTTPServerRequest) {
            lock.lock(); _requests.append(request); lock.unlock()
        }

        var requests: [HTTPServerRequest] {
            lock.lock(); defer { lock.unlock() }; return _requests
        }
    }
}
