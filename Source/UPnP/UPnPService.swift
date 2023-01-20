//
//  UPnPService.swift
//  
//
//  Created by Berrie Kremers on 08/01/2023.
//

import Foundation
import XMLCoder
import Combine

public class UPnPService: Equatable, Identifiable, Hashable {
    public enum SubscriptionStatus {
        case unsubscribed
        case subscribing
        case subscribed
        case unsubscribing
        case renewing
        case failed
    }
    
    public static var defaultSubscriptionTimeout = 1800
    
    public let controlUrl: URL
    public let scpdUrl: URL
    public let eventUrl: URL
    public let serviceType: String
    public let serviceId: String
    public internal(set) unowned var device: UPnPDevice
    public var eventCallbackUrl: URL?
    
    private var serviceDefinition: UPnPServiceDefinition?
    
    private let eventPublisher: AnyPublisher<(String, Data), Never>
    internal lazy var subscribedEventPublisher: AnyPublisher<Data, Never> = {
        eventPublisher.share()
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
    
    internal init(device: UPnPDevice, controlUrl: URL, scpdUrl: URL, eventUrl: URL, serviceType: String, serviceId: String, eventPublisher: AnyPublisher<(String, Data), Never>, eventCallbackUrl: URL?) {
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
        var request = URLRequest(url: scpdUrl)
        request.httpMethod = "GET"
        
        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            print("Error")
            return
        }
        
        do {
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = false
            serviceDefinition = try decoder.decode(UPnPServiceDefinition.self, from: data)
            print("Service parsed with \(serviceDefinition?.actionList.action.count ?? 0) actions")
        }
        catch DecodingError.dataCorrupted(let context) {
            print(context.debugDescription)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("\(key.stringValue) was not found, \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("\(type) was expected, \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("no value was found for \(type), \(context.debugDescription)")
        } catch {
            print("I know not this error")
        }
        
    }
    
    internal func post(action: String, envelope: Codable) async throws {
        var request = URLRequest(url: controlUrl)
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\(id)#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        let encoder = XMLEncoder()
        let httpBody = try? encoder.encode(envelope,
                                           withRootKey: "s:Envelope",
                                           rootAttributes: ["xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                                                            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"],
                                           header: XMLHeader(version: 1.0, encoding: "UTF-8"))
        
        if let httpBody = httpBody {
            request.httpBody = httpBody
            request.setValue("\(String(decoding: httpBody, as: UTF8.self).count)", forHTTPHeaderField: "Content-Length")
        }
        else {
            print("Encode failed")
        }
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    internal func postWithResult<T: Decodable>(action: String, envelope: Codable) async throws -> T {
        var request = URLRequest(url: controlUrl)
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\(id)#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        let encoder = XMLEncoder()
        let httpBody = try? encoder.encode(envelope,
                                           withRootKey: "s:Envelope",
                                           rootAttributes: ["xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                                                            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"],
                                           header: XMLHeader(version: 1.0, encoding: "UTF-8"))
        
        if let httpBody = httpBody {
            request.httpBody = httpBody
            request.setValue("\(String(decoding: httpBody, as: UTF8.self).count)", forHTTPHeaderField: "Content-Length")
        }
        else {
            print("Encode failed")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = false
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func subscribeToEvents() async {
        guard let eventCallbackUrl = eventCallbackUrl else { return }
        guard await startSubcribing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("<\(eventCallbackUrl.absoluteString)>", forHTTPHeaderField: "CALLBACK")
        request.setValue("upnp:event", forHTTPHeaderField: "NT")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")
        
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200,
              (response as? HTTPURLResponse)?.statusCode ?? 0 <= 204 else {
            await setSubcriptionStatus(.failed, subscriptionId: nil)
            return
        }
        
        if let typedHeaderFields = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] {
            let headerFields = Dictionary(uniqueKeysWithValues: typedHeaderFields.map { key, value in (key.uppercased(), value) })
            if let subscriptionId = headerFields["SID"],
               let timeoutString = headerFields["TIMEOUT"],
               let secondKeywordRange = timeoutString.range(of: "Second-"),
               let timeout = UInt64(timeoutString[secondKeywordRange.upperBound...]) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: timeout * 1000000)) { [weak self] in
//                    guard let self else { return }
//                    Task {
//                        await self.renewSubscriptionToEvents()
//                    }
                }
                
                print("Successfully subscribed for: \(timeout) seconds sid: \(subscriptionId)")
                await setSubcriptionStatus(.subscribed, subscriptionId: subscriptionId)
            }
        }
    }
    
    internal func renewSubscriptionToEvents() async {
        guard let subscriptionId = await startRenewing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "SUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("\(subscriptionId)", forHTTPHeaderField: "SID")
        request.setValue("Second-\(Self.defaultSubscriptionTimeout)", forHTTPHeaderField: "TIMEOUT")
        
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200,
              (response as? HTTPURLResponse)?.statusCode ?? 0 <= 204 else {
            await self.setSubcriptionStatus(.failed, subscriptionId: nil)
            return
        }
        
        if let typedHeaderFields = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] {
            let headerFields = Dictionary(uniqueKeysWithValues: typedHeaderFields.map { key, value in (key.uppercased(), value) })
            if let subscriptionId = headerFields["SID"],
               let timeoutString = headerFields["TIMEOUT"],
               let secondKeywordRange = timeoutString.range(of: "Second-"),
               let timeout = UInt64(timeoutString[secondKeywordRange.upperBound...]) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: timeout * 1000000)) { [weak self] in
                    guard let self else { return }
                    Task {
                        await self.renewSubscriptionToEvents()
                    }
                }
                
                print("Successfully renewed for: \(timeout) seconds sid: \(subscriptionId)")
                await self.setSubcriptionStatus(.subscribed, subscriptionId: subscriptionId)
            }
        }
    }
    
    public func unsubscribeFromEvents() async {
        guard await startUnubcribing() else { return }
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "UNSUBSCRIBE"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(subscriptionId, forHTTPHeaderField: "SID")
        
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200,
              (response as? HTTPURLResponse)?.statusCode ?? 0 <= 204 else {
            print("Unsuccessfully unsubscribed sid: \(subscriptionId)")
            await self.setSubcriptionStatus(.failed, subscriptionId: nil)
            return
        }
        
        print("Successfully unsubscribed sid: \(subscriptionId)")
        await self.setSubcriptionStatus(.unsubscribed, subscriptionId: nil)
    }
}
