//
//  UPnPService.swift
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
import Combine
import os.log

public class UPnPService: Equatable, Identifiable, Hashable, @unchecked Sendable {
    public enum SubscriptionStatus {
        case unsubscribed
        case subscribing
        case subscribed
        case unsubscribing
        case renewing
        case failed
    }
    
    public enum MessageLog {
        case none
        case body
        case response
        case bodyAndResponse
    }
    
    public static var defaultSubscriptionTimeout = 120
    
    public let controlUrl: URL
    public let scpdUrl: URL
    public let eventUrl: URL?
    public let serviceType: String
    public let serviceId: String
    public internal(set) unowned var device: UPnPDevice
    public var eventCallbackUrl: URL?
    
    private var serviceDefinition: UPnPServiceDefinition?
    
    private let eventPublisher: AnyPublisher<(String, Data), Never>?
    internal lazy var subscribedEventPublisher: AnyPublisher<Data, Never> = {
        guard let eventPublisher else { return Empty().eraseToAnyPublisher() }
        
        return eventPublisher.share()
            .filter { [weak self] in
                self?.subscriptionId == $0.0
            }
            .map {
                $0.1
            }
            .eraseToAnyPublisher()
    }()
    private var subscriptionId: String?
    @MainActor
    public private(set) var subscriptionStatus = SubscriptionStatus.unsubscribed
    @MainActor
    private func setSubcriptionStatus(_ subscriptionStatus: SubscriptionStatus, subscriptionId: String?) {
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionId = subscriptionId
    }

    /// The task that keeps the subscription alive. Its presence means a subscription is wanted;
    /// it is the only thing that subscribes or renews, which is what keeps those serialized.
    @MainActor
    private var maintenanceTask: Task<Void, Never>?
    @MainActor
    private func startMaintenanceIfNeeded() -> Bool {
        guard maintenanceTask == nil else { return false }

        maintenanceTask = Task { [weak self] in
            var failures = 0

            while Task.isCancelled == false {
                let secondsUntilNextAttempt: Int

                // Hold on to the service only while an attempt is in flight, so that it can be
                // released while the loop waits for the next renewal.
                if let self {
                    if let seconds = await self.performSubscriptionAttempt() {
                        failures = 0
                        secondsUntilNextAttempt = seconds
                    }
                    else {
                        failures += 1
                        secondsUntilNextAttempt = Self.retryDelays[min(failures - 1, Self.retryDelays.count - 1)]
                    }
                }
                else {
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(secondsUntilNextAttempt) * 1_000_000_000)
            }
        }
        return true
    }
    @MainActor
    private func cancelMaintenance() {
        maintenanceTask?.cancel()
        maintenanceTask = nil
    }

    /// Seconds to wait before retrying a subscription, per consecutive failure. The last value is
    /// used for all further attempts.
    private static let retryDelays = [1, 2, 5, 10, 20, 30]

    private let eventStateLock = NSLock()
    private var _lastEventReceived: Date?
    private var _subscriptionActiveSince: Date?
    private var eventObserver: AnyCancellable?

    /// When the last state change for this service was received, or nil if nothing was received
    /// since the current subscription was established.
    public var lastEventReceived: Date? {
        eventStateLock.lock(); defer { eventStateLock.unlock() }; return _lastEventReceived
    }

    /// How long this service has been silent: the time since the last state change was received,
    /// or since the subscription was established when nothing has been received yet. Nil when
    /// there is no active subscription, in which case silence is to be expected.
    ///
    /// A device reports the full state of a service right after subscribing, so silence that lasts
    /// meaningfully longer than a subscription is young is a sign that events are not reaching us,
    /// even though subscribing and renewing keep reporting success.
    public var eventSilence: TimeInterval? {
        eventStateLock.lock(); defer { eventStateLock.unlock() }

        guard let reference = _lastEventReceived ?? _subscriptionActiveSince else { return nil }
        return Date().timeIntervalSince(reference)
    }

    private func markSubscriptionActive() {
        eventStateLock.lock()
        _subscriptionActiveSince = Date()
        _lastEventReceived = nil
        eventStateLock.unlock()
    }

    private func markSubscriptionInactive() {
        eventStateLock.lock()
        _subscriptionActiveSince = nil
        _lastEventReceived = nil
        eventStateLock.unlock()
    }

    /// Record incoming events, so that a subscription that stopped delivering can be detected.
    private func observeEventsIfNeeded() {
        guard eventObserver == nil else { return }

        eventObserver = subscribedEventPublisher
            .sink { [weak self] _ in
                guard let self else { return }

                self.eventStateLock.lock()
                self._lastEventReceived = Date()
                self.eventStateLock.unlock()
            }
    }

    private var bag = Set<AnyCancellable>()

    internal init(device: UPnPDevice, controlUrl: URL, scpdUrl: URL, eventUrl: URL?, serviceType: String, serviceId: String, eventPublisher: AnyPublisher<(String, Data), Never>? = nil, eventCallbackUrl: URL? = nil) {
        self.device = device
        self.controlUrl = controlUrl
        self.scpdUrl = scpdUrl
        self.eventUrl = eventUrl
        self.serviceType = serviceType
        self.serviceId = serviceId
        self.eventPublisher = eventPublisher
        self.eventCallbackUrl = eventCallbackUrl
    }
    
    public static func == (lhs: UPnPService, rhs: UPnPService) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: String {
        "\(device.uuid)::\(serviceId)"
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    var description: String {
        "Service id: \(id)\ncontrolUrl: \(controlUrl)"
    }
    
    func loadScdp() async {
        var request = URLRequest(url: scpdUrl, timeoutInterval: 3.0)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "GET"
        
        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            Logger.swiftUPnP.error("Couldn't load service definition from \(self.scpdUrl.absoluteString)")
            return
        }
        
        do {
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = false
            serviceDefinition = try decoder.decode(UPnPServiceDefinition.self, from: data)
            Logger.swiftUPnP.debug("Service parsed with \(self.serviceDefinition?.actionList.action.count ?? 0) actions")
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
    
    internal func post(action: String, envelope: Codable, log: MessageLog = .none) async throws {
        var request = URLRequest(url: controlUrl)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\(serviceType)#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 5
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("0", forHTTPHeaderField: "Expires")

        let encoder = XMLEncoder()
        let httpBody = try encoder.encode(envelope,
                                          withRootKey: "s:Envelope",
                                          rootAttributes: ["xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                                                           "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"],
                                          header: XMLHeader(version: 1.0, encoding: "UTF-8"))
    
        request.httpBody = httpBody
        request.setValue("\(String(decoding: httpBody, as: UTF8.self).count)", forHTTPHeaderField: "Content-Length")
        if log == .body || log == .bodyAndResponse, let httpBodyString = String(data: httpBody, encoding: .utf8) {
            Logger.swiftUPnP.info("Body(\(action)): \(httpBodyString)")
        }
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    internal func postWithResult<T: Decodable>(action: String, envelope: Codable, log: MessageLog = .none) async throws -> T {
        var request = URLRequest(url: controlUrl)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\(serviceType)#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 5
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("0", forHTTPHeaderField: "Expires")
        
        let encoder = XMLEncoder()
        let httpBody = try encoder.encode(envelope,
                                          withRootKey: "s:Envelope",
                                          rootAttributes: ["xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                                                           "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"],
                                          header: XMLHeader(version: 1.0, encoding: "UTF-8"))
    
        request.httpBody = httpBody
        request.setValue("\(String(decoding: httpBody, as: UTF8.self).count)", forHTTPHeaderField: "Content-Length")
        if log == .body || log == .bodyAndResponse, let httpBodyString = String(data: httpBody, encoding: .utf8) {
            Logger.swiftUPnP.info("Body(\(action)): \(httpBodyString)")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        if log == .response || log == .bodyAndResponse, let httpResponseBodyString = String(data: data, encoding: .utf8) {
            Logger.swiftUPnP.info("Response Body(\(action)): \(httpResponseBodyString)")
        }
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = false
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Start receiving state changes for this service, and keep receiving them.
    ///
    /// The subscription is maintained until `unsubscribeFromEvents()` is called: renewals that fail
    /// are retried, and a subscription that is rejected or lost is established anew. Calling this
    /// on a service that is already maintaining a subscription does nothing.
    public func subscribeToEvents() async {
        guard eventUrl != nil else { return }

        observeEventsIfNeeded()
        _ = await startMaintenanceIfNeeded()
    }

    /// Establish a fresh subscription, discarding the current one.
    ///
    /// Use this when events are known to no longer arrive even though the subscription looks
    /// healthy: subscribing anew gets a new subscription id and makes the device report the full
    /// state of the service again, which also confirms that events can reach us at all.
    public func resubscribeToEvents() async {
        guard eventUrl != nil else { return }

        await cancelMaintenance()
        await discardSubscription()
        await subscribeToEvents()
    }

    /// Establish or renew the subscription once, and report how many seconds from now the next
    /// renewal is due. Nil when the attempt failed, in which case the caller decides how long to
    /// wait before trying again.
    ///
    /// Subscribing and renewing fail regularly in practice: a player reboots, a network hiccup
    /// swallows a request, a device forgets a subscription or refuses a new one. None of that may
    /// end the maintenance loop, because a subscription that is not restored means no more state
    /// changes for the rest of the session.
    private func performSubscriptionAttempt() async -> Int? {
        let currentSubscriptionId = await subscriptionIdForRenewal()
        let result = currentSubscriptionId == nil ? await sendSubscribe() : await sendRenew(subscriptionId: currentSubscriptionId!)

        // A cancelled attempt is one that was replaced by a newer one (or by unsubscribing), and
        // must not report its outcome over that of its successor.
        guard Task.isCancelled == false else { return nil }

        switch result {
        case let .subscribed(subscriptionId, timeout):
            if currentSubscriptionId != subscriptionId {
                markSubscriptionActive()
            }
            await setSubcriptionStatus(.subscribed, subscriptionId: subscriptionId)

            return Self.renewalDelay(forTimeout: timeout)
        case .failed:
            // Drop the subscription rather than renewing it again: it may no longer exist on the
            // device, in which case only a new subscription recovers.
            await discardSubscription()

            return nil
        }
    }

    @MainActor
    private func subscriptionIdForRenewal() -> String? {
        guard subscriptionStatus == .subscribed else { return nil }
        return subscriptionId
    }

    private func discardSubscription() async {
        markSubscriptionInactive()
        await setSubcriptionStatus(.failed, subscriptionId: nil)
    }

    /// Renew well before the subscription expires, so a single failed renewal can still be retried
    /// while the subscription is alive.
    private static func renewalDelay(forTimeout timeout: Int) -> Int {
        max(Int(Double(timeout) * 0.8), 5)
    }

    private enum SubscriptionResult {
        case subscribed(subscriptionId: String, timeout: Int)
        case failed
    }

    private func sendSubscribe() async -> SubscriptionResult {
        guard let eventUrl, let eventCallbackUrl else {
            Logger.swiftUPnP.error("Can't subscribe to \(self.serviceId) without a callback url to receive events on")
            return .failed
        }

        await setSubcriptionStatus(.subscribing, subscriptionId: nil)

        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("<\(eventCallbackUrl.absoluteString)>", forHTTPHeaderField: "CALLBACK")
        request.setValue("upnp:event", forHTTPHeaderField: "NT")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")

        return await send(request: request, type: "subscribed")
    }

    private func sendRenew(subscriptionId: String) async -> SubscriptionResult {
        guard let eventUrl else { return .failed }

        await setSubcriptionStatus(.renewing, subscriptionId: subscriptionId)

        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("\(subscriptionId)", forHTTPHeaderField: "SID")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")

        return await send(request: request, type: "renewed")
    }

    private func send(request: URLRequest, type: String) async -> SubscriptionResult {
        await UPnPRegistry.shared.startHTTPServerIfNotRunning()

        guard let (_, response) = try? await URLSession.shared.data(for: request) else {
            Logger.swiftUPnP.error("\(type) failed request \(request.url!.description)")
            return .failed
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode >= 200, statusCode <= 204 else {
            Logger.swiftUPnP.error("\(type) failed, status = \(statusCode)")
            return .failed
        }

        guard let typedHeaderFields = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] else {
            Logger.swiftUPnP.error("\(type) failed, response without headers")
            return .failed
        }

        let headerFields = Dictionary(uniqueKeysWithValues: typedHeaderFields.map { key, value in (key.uppercased(), value) })
        // Without a subscription id events can't be recognized as ours, so this is a failure even
        // though the device reported success.
        guard let subscriptionId = headerFields["SID"] else {
            Logger.swiftUPnP.error("\(type) failed, response without a subscription id")
            return .failed
        }

        // A device is allowed to answer with a timeout of "infinite", and some answer with a value
        // that can't be read at all. Renew on our own schedule in that case, which also keeps
        // checking that the device is still there.
        var timeout = Self.defaultSubscriptionTimeout
        if let timeoutString = headerFields["TIMEOUT"],
           let secondKeywordRange = timeoutString.range(of: "Second-"),
           let reportedTimeout = Int(timeoutString[secondKeywordRange.upperBound...]) {
            timeout = reportedTimeout
        }

        Logger.swiftUPnP.debug("Successfully \(type) for: \(timeout) seconds sid: \(subscriptionId), will renew in \(Self.renewalDelay(forTimeout: timeout)) seconds")
        return .subscribed(subscriptionId: subscriptionId, timeout: timeout)
    }

    public func unsubscribeFromEvents() async {
        await cancelMaintenance()

        guard let eventUrl, let subscriptionId = await activeSubscriptionId() else {
            await setSubcriptionStatus(.unsubscribed, subscriptionId: nil)
            markSubscriptionInactive()
            return
        }

        await setSubcriptionStatus(.unsubscribing, subscriptionId: subscriptionId)
        markSubscriptionInactive()

        var request = URLRequest(url: eventUrl)
        request.httpMethod = "UNSUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(subscriptionId, forHTTPHeaderField: "SID")

        // The subscription is gone as far as we are concerned either way: if the device didn't get
        // the message it drops the subscription when it expires.
        if let (_, response) = try? await URLSession.shared.data(for: request),
           (200...204).contains((response as? HTTPURLResponse)?.statusCode ?? -1) {
            Logger.swiftUPnP.debug("Successfully unsubscribed sid: \(subscriptionId)")
        }
        else {
            Logger.swiftUPnP.error("Unsuccessfully unsubscribed sid: \(subscriptionId)")
        }

        await setSubcriptionStatus(.unsubscribed, subscriptionId: nil)
    }

    @MainActor
    private func activeSubscriptionId() -> String? {
        subscriptionId
    }
}
