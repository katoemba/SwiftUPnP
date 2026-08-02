//
//  HTTPServer.swift
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

import Foundation
import Network
import os.log

/// A request as it arrived from a device.
struct HTTPServerRequest {
    /// Upper-cased, so that a device that writes `notify` is treated like one that writes `NOTIFY`.
    /// UPnP uses methods that are not part of the standard http set (NOTIFY, SUBSCRIBE,
    /// UNSUBSCRIBE), which is why nothing here rejects a method it doesn't recognize.
    let method: String
    /// The path of the request target, without the query.
    let path: String
    /// Keyed by upper-cased field name, values of repeated fields are joined with a comma.
    let headers: [String: String]
    let body: Data

    func header(_ name: String) -> String? {
        headers[name.uppercased()]
    }
}

struct HTTPServerResponse {
    var statusCode: Int
    var reasonPhrase: String
    /// `Content-Length` and `Connection` are written by the server itself and are ignored here.
    var headers = [String: String]()
    var body = Data()

    static func ok(headers: [String: String] = [:], body: Data = Data()) -> HTTPServerResponse {
        HTTPServerResponse(statusCode: 200, reasonPhrase: "OK", headers: headers, body: body)
    }

    static func status(_ statusCode: Int, _ reasonPhrase: String, headers: [String: String] = [:]) -> HTTPServerResponse {
        HTTPServerResponse(statusCode: statusCode, reasonPhrase: reasonPhrase, headers: headers)
    }

    static func notFound() -> HTTPServerResponse {
        .status(404, "Not Found")
    }

    static func internalServerError(_ message: String) -> HTTPServerResponse {
        HTTPServerResponse(statusCode: 500, reasonPhrase: "Internal Server Error", body: Data(message.utf8))
    }
}

/// A minimal http/1.1 server, enough to receive the event notifications that devices post to us and
/// to answer them. It handles the methods UPnP adds to http, keep-alive connections and both
/// `Content-Length` and chunked bodies; it does not serve files, do https, or anything else that
/// isn't needed to be the receiving end of a UPnP subscription.
///
/// Failure of a running listener is reported through ``onFailure``: without it a listener that stops
/// accepting connections is invisible from the outside, and the events simply stop arriving.
final class HTTPServer {
    typealias Handler = (HTTPServerRequest) -> HTTPServerResponse

    enum ServerError: LocalizedError {
        case invalidPort(UInt16)
        case failedToListen(port: UInt16, underlying: Error)

        var errorDescription: String? {
            switch self {
            case let .invalidPort(port):
                return "\(port) is not a valid port number"
            case let .failedToListen(port, underlying):
                return "Couldn't listen on port \(port): \(underlying.localizedDescription)"
            }
        }
    }

    /// Called when a listener that was running stopped on its own, which happens when the network it
    /// was bound to disappears. Not called for a listener that is stopped through ``stop()``, and
    /// not called for a listener that never started: that is reported by ``start(port:)`` throwing.
    ///
    /// Called on an internal queue.
    var onFailure: ((Error) -> Void)?

    /// Answers the requests that arrive, on a queue of the connection they arrived over. Set it
    /// before starting; a request that arrives without one is answered with an error.
    var handler: Handler? {
        get { lock.lock(); defer { lock.unlock() }; return _handler }
        set { lock.lock(); _handler = newValue; lock.unlock() }
    }

    private let requestTimeout: TimeInterval
    private let queue = DispatchQueue(label: "com.katoemba.swiftupnp.httpserver")
    private let lock = NSLock()
    /// Listeners that were told to stop but haven't reported doing so. Their port is still taken,
    /// which matters because a restart binds the port it was already using.
    private let cancellations = DispatchGroup()
    private var _handler: Handler?
    private var listener: NWListener?
    private var connections = [ObjectIdentifier: HTTPConnection]()
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var _isRunning = false
    private var _port: UInt16 = 0

    /// - Parameter requestTimeout: how long a request that has started arriving may take to arrive
    ///   in full before its connection is given up on.
    init(requestTimeout: TimeInterval = 30) {
        self.requestTimeout = requestTimeout
    }

    deinit {
        stop()
    }

    /// Whether the listener is accepting connections. False both before it is started and after it
    /// failed, which is what makes it worth checking.
    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isRunning
    }

    /// The port that is being listened on, which is the port that was asked for. 0 when not running.
    var port: UInt16 {
        lock.lock(); defer { lock.unlock() }
        return _port
    }

    /// Start listening, and return once the listener is either accepting connections or has failed
    /// to bind. Any listener that was running is stopped first.
    func start(port: UInt16) async throws {
        stop()
        // Stopping is not immediate, and until it completes the port is still taken. Waiting is what
        // makes restarting on the same port work, which is how event delivery is recovered.
        await waitForCancellations()

        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw ServerError.invalidPort(port)
        }

        let parameters = NWParameters.tcp
        // Devices reconnect to this port right after it was released, which fails for as long as the
        // previous socket lingers.
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = false
        if let tcp = parameters.defaultProtocolStack.internetProtocol as? NWProtocolTCP.Options {
            // A device that disappears without closing its connection leaves it open forever
            // otherwise, and events are far enough apart that nothing else would notice.
            tcp.enableKeepalive = true
            tcp.keepaliveIdle = 60
        }

        let listener: NWListener
        do {
            listener = try NWListener(using: parameters, on: endpointPort)
        }
        catch {
            throw ServerError.failedToListen(port: port, underlying: error)
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.stateUpdateHandler = { [weak self] state in
            self?.handleStateChange(state, of: listener, port: port)
        }

        store(listener)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            startContinuation = continuation
            lock.unlock()

            listener.start(queue: queue)
        }
    }

    /// Separate from ``start(port:)`` because the lock may not be taken from an async context.
    private func store(_ listener: NWListener) {
        lock.lock()
        self.listener = listener
        lock.unlock()
    }

    func stop() {
        lock.lock()
        let listener = self.listener
        let connections = self.connections
        let continuation = startContinuation
        self.listener = nil
        self.connections.removeAll()
        startContinuation = nil
        _isRunning = false
        _port = 0
        lock.unlock()

        if let listener {
            cancel(listener)
        }
        for connection in connections.values {
            connection.close()
        }

        continuation?.resume(throwing: CancellationError())
    }

    /// Stop a listener and keep track of it until it reports that it did, so that the port it holds
    /// isn't bound again while it is still letting go of it.
    private func cancel(_ listener: NWListener) {
        cancellations.enter()
        let leave = Once { [cancellations] in cancellations.leave() }

        listener.newConnectionHandler = nil
        // Replaced rather than cleared, so that the cancellation isn't reported as a failure.
        listener.stateUpdateHandler = { state in
            if case .cancelled = state {
                leave.run()
            }
        }
        listener.cancel()

        // A listener that never reports being cancelled may not hold up the next start forever.
        queue.asyncAfter(deadline: .now() + 2) {
            leave.run()
        }
    }

    private func waitForCancellations() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let resume = Once { continuation.resume() }
            cancellations.notify(queue: queue) { resume.run() }
        }
    }

    private func handleStateChange(_ state: NWListener.State, of listener: NWListener, port: UInt16) {
        switch state {
        case .ready:
            lock.lock()
            _isRunning = true
            _port = listener.port?.rawValue ?? port
            let continuation = startContinuation
            startContinuation = nil
            lock.unlock()

            Logger.swiftUPnP.debug("Listening for events on port \(self.port)")
            continuation?.resume()

        case let .failed(error):
            report(error, of: listener, port: port)

        case let .waiting(error):
            // A listener that is waiting retries by itself, endlessly and without ever becoming
            // ready when the port is taken. Both while starting and while running that is the
            // situation the caller needs to hear about rather than wait out.
            report(error, of: listener, port: port)

        default:
            break
        }
    }

    /// Report a listener that isn't accepting connections to whoever can do something about it: the
    /// caller of `start` when it is still waiting, ``onFailure`` when it isn't.
    private func report(_ error: Error, of listener: NWListener, port: UInt16) {
        lock.lock()
        guard self.listener === listener else {
            // Already replaced or stopped, its failure is no longer of interest.
            lock.unlock()
            return
        }
        let continuation = startContinuation
        let wasRunning = _isRunning
        startContinuation = nil
        self.listener = nil
        _isRunning = false
        _port = 0
        let connections = self.connections
        self.connections.removeAll()
        lock.unlock()

        cancel(listener)
        for connection in connections.values {
            connection.close()
        }

        let serverError = ServerError.failedToListen(port: port, underlying: error)
        if let continuation {
            continuation.resume(throwing: serverError)
        }
        else if wasRunning {
            Logger.swiftUPnP.error("Stopped listening on port \(port): \(error.localizedDescription)")
            onFailure?(serverError)
        }
    }

    private func accept(_ connection: NWConnection) {
        let handler = self.handler ?? { _ in .internalServerError("No handler is listening") }
        let httpConnection = HTTPConnection(connection: connection, handler: handler, requestTimeout: requestTimeout) { [weak self] finished in
            guard let self else { return }
            self.lock.lock()
            self.connections.removeValue(forKey: ObjectIdentifier(finished))
            self.lock.unlock()
        }

        lock.lock()
        guard _isRunning else {
            lock.unlock()
            connection.cancel()
            return
        }
        connections[ObjectIdentifier(httpConnection)] = httpConnection
        lock.unlock()

        httpConnection.start()
    }
}

/// Runs its work exactly once, for whichever of two things that both mean 'done' happens first.
private final class Once {
    private let lock = NSLock()
    private var work: (() -> Void)?

    init(_ work: @escaping () -> Void) {
        self.work = work
    }

    func run() {
        lock.lock()
        let work = self.work
        self.work = nil
        lock.unlock()

        work?()
    }
}

/// One connection from a device, which may carry more than one request: devices keep the connection
/// open between notifications.
private final class HTTPConnection {
    private static let maximumHeaderSize = 64 * 1024
    private static let maximumBodySize = 8 * 1024 * 1024

    private let connection: NWConnection
    private let handler: HTTPServer.Handler
    /// How long a request that has started arriving may take to arrive in full. A device that opens
    /// a connection and then says nothing holds on to it forever otherwise. Only applied while a
    /// request is half received, so a quiet keep-alive connection that a device intends to reuse is
    /// left alone.
    private let requestTimeout: TimeInterval
    private let onClose: (HTTPConnection) -> Void
    /// Its own queue, so that a slow handler for one device doesn't hold up the events of another.
    private let queue = DispatchQueue(label: "com.katoemba.swiftupnp.httpconnection")
    private var buffer = Data()
    private var timeout: DispatchWorkItem?
    private var closed = false

    init(connection: NWConnection, handler: @escaping HTTPServer.Handler, requestTimeout: TimeInterval, onClose: @escaping (HTTPConnection) -> Void) {
        self.connection = connection
        self.handler = handler
        self.requestTimeout = requestTimeout
        self.onClose = onClose
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.close()
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    func close() {
        queue.async { [self] in
            guard !closed else { return }
            closed = true

            timeout?.cancel()
            timeout = nil
            connection.stateUpdateHandler = nil
            connection.cancel()
            onClose(self)
        }
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self, !self.closed else { return }

            if let data, data.isEmpty == false {
                self.buffer.append(data)
                guard self.handleBufferedRequests() else { return }
            }

            guard error == nil, isComplete == false else {
                self.close()
                return
            }

            self.receive()
        }
    }

    /// Handle every complete request in the buffer. Returns false when the connection was closed and
    /// there is nothing left to receive.
    private func handleBufferedRequests() -> Bool {
        while true {
            switch HTTPRequestParser.parse(&buffer) {
            case .incomplete:
                guard buffer.count <= Self.maximumHeaderSize + Self.maximumBodySize else {
                    send(.status(413, "Payload Too Large"), keepAlive: false)
                    return false
                }
                // Every handled request leaves an empty buffer that parses as incomplete, which is
                // an idle connection waiting for the next notification rather than a request that
                // stopped halfway: only the latter is given a deadline.
                if buffer.isEmpty {
                    cancelTimeout()
                }
                else {
                    startTimeout()
                }
                return true

            case let .malformed(reason):
                Logger.swiftUPnP.error("Discarding a malformed request: \(reason)")
                send(.status(400, "Bad Request"), keepAlive: false)
                return false

            case let .request(request, keepAlive):
                cancelTimeout()
                send(handler(request), keepAlive: keepAlive)
                guard keepAlive else { return false }
            }
        }
    }

    private func send(_ response: HTTPServerResponse, keepAlive: Bool) {
        var head = "HTTP/1.1 \(response.statusCode) \(response.reasonPhrase)\r\n"
        for (name, value) in response.headers {
            // Written by us below, whatever a handler has to say about them is ignored.
            let lowercased = name.lowercased()
            guard lowercased != "content-length", lowercased != "connection" else { continue }
            head += "\(Self.sanitized(name)): \(Self.sanitized(value))\r\n"
        }
        head += "Content-Length: \(response.body.count)\r\n"
        head += "Connection: \(keepAlive ? "keep-alive" : "close")\r\n\r\n"

        var data = Data(head.utf8)
        data.append(response.body)

        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil || keepAlive == false {
                self?.close()
            }
        })
    }

    /// Header names and values end up in the response as they are, so anything that could end the
    /// line early is taken out.
    private static func sanitized(_ value: String) -> String {
        value.filter { $0 != "\r" && $0 != "\n" }
    }

    private func startTimeout() {
        guard timeout == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.closed == false else { return }
            Logger.swiftUPnP.debug("Closing a connection that stopped halfway through a request")
            self.close()
        }
        timeout = work
        queue.asyncAfter(deadline: .now() + requestTimeout, execute: work)
    }

    private func cancelTimeout() {
        timeout?.cancel()
        timeout = nil
    }
}

/// Turns the bytes that arrived into requests. Split out from the connection so it can be tested on
/// its own, since this is where a device that phrases things differently than expected shows up.
enum HTTPRequestParser {
    enum Result {
        /// Not everything has arrived yet, nothing was consumed.
        case incomplete
        /// Unusable, the connection can only be closed.
        case malformed(String)
        /// A request, consumed from the buffer. `keepAlive` is whether the connection is to be held
        /// open for a next one.
        case request(HTTPServerRequest, keepAlive: Bool)
    }

    private static let headerTerminator = Data([0x0d, 0x0a, 0x0d, 0x0a])
    private static let crlf = Data([0x0d, 0x0a])

    /// Parse the first request in `buffer`, consuming it when it is complete.
    static func parse(_ buffer: inout Data) -> Result {
        guard let terminator = buffer.range(of: headerTerminator) else { return .incomplete }

        let head = buffer[buffer.startIndex..<terminator.lowerBound]
        guard let text = String(data: Data(head), encoding: .utf8) else {
            return .malformed("the header block is not valid utf8")
        }

        var lines = text.components(separatedBy: "\r\n")
        guard lines.isEmpty == false else { return .malformed("there is no request line") }

        let requestLine = lines.removeFirst().split(separator: " ", omittingEmptySubsequences: true)
        guard requestLine.count >= 2 else { return .malformed("the request line is incomplete") }

        let method = String(requestLine[0]).uppercased()
        let target = String(requestLine[1])
        let version = requestLine.count > 2 ? String(requestLine[2]).uppercased() : "HTTP/1.1"

        var headers = [String: String]()
        for line in lines {
            guard let separator = line.firstIndex(of: ":") else {
                return .malformed("header line '\(line)' has no colon")
            }
            let name = line[line.startIndex..<separator].trimmingCharacters(in: .whitespaces).uppercased()
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if let existing = headers[name] {
                headers[name] = "\(existing), \(value)"
            }
            else {
                headers[name] = value
            }
        }

        let bodyStart = terminator.upperBound
        let body: Data
        let bodyLength: Int
        if headers["TRANSFER-ENCODING"]?.lowercased().contains("chunked") == true {
            guard let chunked = parseChunkedBody(buffer[bodyStart...]) else { return .incomplete }
            body = chunked.body
            bodyLength = chunked.length
        }
        else if let contentLength = headers["CONTENT-LENGTH"] {
            guard let length = Int(contentLength.trimmingCharacters(in: .whitespaces)), length >= 0 else {
                return .malformed("'\(contentLength)' is not a content length")
            }
            guard buffer.endIndex - bodyStart >= length else { return .incomplete }
            body = Data(buffer[bodyStart..<(bodyStart + length)])
            bodyLength = length
        }
        else {
            body = Data()
            bodyLength = 0
        }

        buffer = Data(buffer[(bodyStart + bodyLength)...])

        // A path is all the routing here needs, and a device is free to send an absolute url.
        let path = URLComponents(string: target)?.percentEncodedPath ?? target

        let connectionHeader = headers["CONNECTION"]?.lowercased() ?? ""
        let keepAlive = connectionHeader.contains("close") ? false
                      : version == "HTTP/1.0" ? connectionHeader.contains("keep-alive")
                      : true

        return .request(HTTPServerRequest(method: method, path: path, headers: headers, body: body),
                        keepAlive: keepAlive)
    }

    /// Returns nil while the body is still arriving, and the number of bytes the chunks occupy so
    /// the caller can consume exactly those.
    private static func parseChunkedBody(_ data: Data) -> (body: Data, length: Int)? {
        var body = Data()
        var position = data.startIndex

        while true {
            guard let lineEnd = data.range(of: crlf, in: position..<data.endIndex) else { return nil }

            let sizeLine = String(data: Data(data[position..<lineEnd.lowerBound]), encoding: .utf8) ?? ""
            // A chunk size may carry extensions, separated from the size by a semicolon.
            let size = sizeLine.split(separator: ";").first.map(String.init) ?? sizeLine
            guard let chunkSize = Int(size.trimmingCharacters(in: .whitespaces), radix: 16), chunkSize >= 0 else {
                // Not recoverable, but reported as 'still arriving' so the caller's size limit ends
                // the connection rather than this parser guessing at what was meant.
                return nil
            }

            position = lineEnd.upperBound

            guard chunkSize > 0 else {
                // The last chunk is followed by optional trailers and a final empty line.
                while true {
                    guard let trailerEnd = data.range(of: crlf, in: position..<data.endIndex) else { return nil }
                    let isEmptyLine = trailerEnd.lowerBound == position
                    position = trailerEnd.upperBound
                    if isEmptyLine { return (body, position - data.startIndex) }
                }
            }

            guard data.endIndex - position >= chunkSize + crlf.count else { return nil }
            body.append(Data(data[position..<(position + chunkSize)]))
            position += chunkSize + crlf.count
        }
    }
}
