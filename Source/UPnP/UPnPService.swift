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
    @MainActor
    private func startSubcribing() -> Bool {
        guard subscriptionStatus == .unsubscribed || subscriptionStatus == .failed else { return false }
        subscriptionStatus = .subscribing
        return true
    }
    @MainActor
    private func startRenewing() -> String? {
        guard subscriptionStatus == .subscribed, subscriptionId != nil else { return nil }
        subscriptionStatus = .renewing
        return subscriptionId
    }
    @MainActor
    private func startUnubcribing() -> Bool {
        guard subscriptionStatus == .subscribed, subscriptionId != nil else { return false }
        subscriptionStatus = .unsubscribing
        return true
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
    
    public func subscribeToEvents() async {
        guard let eventUrl = eventUrl, let eventCallbackUrl = eventCallbackUrl else { return }
        guard await startSubcribing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("<\(eventCallbackUrl.absoluteString)>", forHTTPHeaderField: "CALLBACK")
        request.setValue("upnp:event", forHTTPHeaderField: "NT")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")
        
        await subscribeOrRenew(request: request, type: "subscribed")
    }
    
    internal func renewSubscriptionToEvents() async {
        guard let eventUrl = eventUrl, let subscriptionId = await startRenewing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("\(subscriptionId)", forHTTPHeaderField: "SID")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")
        
        await subscribeOrRenew(request: request, type: "renewed")
    }
    
    private func subscribeOrRenew(request: URLRequest, type: String) async {
        await UPnPRegistry.shared.startHTTPServerIfNotRunning()
        
        guard let (_, response) = try? await URLSession.shared.data(for: request) else {
            Logger.swiftUPnP.error("\(type) failed request \(request.url!.description)")
            await self.setSubcriptionStatus(.failed, subscriptionId: nil)
            return
        }
        
        guard (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200,
              (response as? HTTPURLResponse)?.statusCode ?? 0 <= 204 else {
            Logger.swiftUPnP.error("\(type) failed, status = \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            await self.setSubcriptionStatus(.failed, subscriptionId: nil)
            await self.subscribeToEvents()
            return
        }
        
        if let typedHeaderFields = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] {
            let headerFields = Dictionary(uniqueKeysWithValues: typedHeaderFields.map { key, value in (key.uppercased(), value) })
            if let subscriptionId = headerFields["SID"],
               let timeoutString = headerFields["TIMEOUT"],
               let secondKeywordRange = timeoutString.range(of: "Second-"),
               let timeout = Int(timeoutString[secondKeywordRange.upperBound...]) {
                Logger.swiftUPnP.debug("Will renew sid: \(subscriptionId) at: \(Date(timeIntervalSinceNow: Double(timeout - 10)))")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(timeout - 10))) { [weak self] in
                    guard let self else { return }
                    Task {
                        await self.renewSubscriptionToEvents()
                    }
                }
                
                Logger.swiftUPnP.debug("Successfully \(type) for: \(timeout) seconds sid: \(subscriptionId)")
                await self.setSubcriptionStatus(.subscribed, subscriptionId: subscriptionId)
            }
        }
    }
    
    public func unsubscribeFromEvents() async {
        guard let eventUrl = eventUrl, await startUnubcribing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "UNSUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(subscriptionId, forHTTPHeaderField: "SID")
        
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200,
              (response as? HTTPURLResponse)?.statusCode ?? 0 <= 204 else {
            Logger.swiftUPnP.error("Unsuccessfully unsubscribed sid: \(self.subscriptionId ?? "-")")
            await self.setSubcriptionStatus(.failed, subscriptionId: nil)
            return
        }
        
        Logger.swiftUPnP.debug("Successfully unsubscribed sid: \(self.subscriptionId ?? "-")")
        await self.setSubcriptionStatus(.unsubscribed, subscriptionId: nil)
    }
}
