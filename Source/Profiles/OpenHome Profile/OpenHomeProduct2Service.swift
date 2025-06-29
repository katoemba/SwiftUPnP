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
//  Generated by SwiftUPnP/UPnPCodeGenerator
//

import Foundation
import Combine
import XMLCoder
import os.log

public class OpenHomeProduct2Service: UPnPService, @unchecked Sendable {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct ManufacturerResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case name = "Name"
			case info = "Info"
			case url = "Url"
			case imageUri = "ImageUri"
		}

		public var name: String
		public var info: String
		public var url: String
		public var imageUri: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))ManufacturerResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))name: '\(name)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))info: '\(info)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))url: '\(url)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))imageUri: '\(imageUri)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func manufacturer(log: UPnPService.MessageLog = .none) async throws -> ManufacturerResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Manufacturer"
				case response = "u:ManufacturerResponse"
			}

			var action: SoapAction?
			var response: ManufacturerResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Manufacturer", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ModelResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case name = "Name"
			case info = "Info"
			case url = "Url"
			case imageUri = "ImageUri"
		}

		public var name: String
		public var info: String
		public var url: String
		public var imageUri: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))ModelResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))name: '\(name)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))info: '\(info)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))url: '\(url)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))imageUri: '\(imageUri)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func model(log: UPnPService.MessageLog = .none) async throws -> ModelResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Model"
				case response = "u:ModelResponse"
			}

			var action: SoapAction?
			var response: ModelResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Model", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ProductResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case room = "Room"
			case name = "Name"
			case info = "Info"
			case url = "Url"
			case imageUri = "ImageUri"
		}

		public var room: String
		public var name: String
		public var info: String
		public var url: String
		public var imageUri: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))ProductResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))room: '\(room)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))name: '\(name)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))info: '\(info)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))url: '\(url)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))imageUri: '\(imageUri)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func product(log: UPnPService.MessageLog = .none) async throws -> ProductResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Product"
				case response = "u:ProductResponse"
			}

			var action: SoapAction?
			var response: ProductResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Product", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct StandbyResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))StandbyResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: \(value == true ? "true" : "false")")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func standby(log: UPnPService.MessageLog = .none) async throws -> StandbyResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Standby"
				case response = "u:StandbyResponse"
			}

			var action: SoapAction?
			var response: StandbyResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Standby", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setStandby(value: Bool, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
			}

			@Attribute var urn: String
			public var value: Bool
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetStandby"
			}

			var action: SoapAction
		}
		try await post(action: "SetStandby", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))), log: log)
	}

	public struct SourceCountResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))SourceCountResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: \(value)")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func sourceCount(log: UPnPService.MessageLog = .none) async throws -> SourceCountResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SourceCount"
				case response = "u:SourceCountResponse"
			}

			var action: SoapAction?
			var response: SourceCountResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "SourceCount", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceXmlResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))SourceXmlResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: '\(value)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func sourceXml(log: UPnPService.MessageLog = .none) async throws -> SourceXmlResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SourceXml"
				case response = "u:SourceXmlResponse"
			}

			var action: SoapAction?
			var response: SourceXmlResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "SourceXml", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceIndexResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))SourceIndexResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: \(value)")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func sourceIndex(log: UPnPService.MessageLog = .none) async throws -> SourceIndexResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SourceIndex"
				case response = "u:SourceIndexResponse"
			}

			var action: SoapAction?
			var response: SourceIndexResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "SourceIndex", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setSourceIndex(value: UInt32, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
			}

			@Attribute var urn: String
			public var value: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetSourceIndex"
			}

			var action: SoapAction
		}
		try await post(action: "SetSourceIndex", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))), log: log)
	}

	public func setSourceIndexByName(value: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
			}

			@Attribute var urn: String
			public var value: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetSourceIndexByName"
			}

			var action: SoapAction
		}
		try await post(action: "SetSourceIndexByName", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))), log: log)
	}

	public func setSourceBySystemName(value: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
			}

			@Attribute var urn: String
			public var value: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetSourceBySystemName"
			}

			var action: SoapAction
		}
		try await post(action: "SetSourceBySystemName", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))), log: log)
	}

	public struct SourceResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case systemName = "SystemName"
			case type = "Type"
			case name = "Name"
			case visible = "Visible"
		}

		public var systemName: String
		public var type: String
		public var name: String
		public var visible: Bool

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))SourceResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))systemName: '\(systemName)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))type: '\(type)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))name: '\(name)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))visible: \(visible == true ? "true" : "false")")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func source(index: UInt32, log: UPnPService.MessageLog = .none) async throws -> SourceResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case index = "Index"
			}

			@Attribute var urn: String
			public var index: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Source"
				case response = "u:SourceResponse"
			}

			var action: SoapAction?
			var response: SourceResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Source", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), index: index))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct AttributesResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))AttributesResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: '\(value)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func attributes(log: UPnPService.MessageLog = .none) async throws -> AttributesResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Attributes"
				case response = "u:AttributesResponse"
			}

			var action: SoapAction?
			var response: AttributesResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Attributes", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceXmlChangeCountResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))SourceXmlChangeCountResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: \(value)")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func sourceXmlChangeCount(log: UPnPService.MessageLog = .none) async throws -> SourceXmlChangeCountResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SourceXmlChangeCount"
				case response = "u:SourceXmlChangeCountResponse"
			}

			var action: SoapAction?
			var response: SourceXmlChangeCountResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "SourceXmlChangeCount", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeProduct2Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case manufacturerName = "ManufacturerName"
			case manufacturerInfo = "ManufacturerInfo"
			case manufacturerUrl = "ManufacturerUrl"
			case manufacturerImageUri = "ManufacturerImageUri"
			case modelName = "ModelName"
			case modelInfo = "ModelInfo"
			case modelUrl = "ModelUrl"
			case modelImageUri = "ModelImageUri"
			case productRoom = "ProductRoom"
			case productName = "ProductName"
			case productInfo = "ProductInfo"
			case productUrl = "ProductUrl"
			case productImageUri = "ProductImageUri"
			case standby = "Standby"
			case sourceIndex = "SourceIndex"
			case sourceCount = "SourceCount"
			case sourceXml = "SourceXml"
			case attributes = "Attributes"
		}

		public var manufacturerName: String?
		public var manufacturerInfo: String?
		public var manufacturerUrl: String?
		public var manufacturerImageUri: String?
		public var modelName: String?
		public var modelInfo: String?
		public var modelUrl: String?
		public var modelImageUri: String?
		public var productRoom: String?
		public var productName: String?
		public var productInfo: String?
		public var productUrl: String?
		public var productImageUri: String?
		public var standby: Bool?
		public var sourceIndex: UInt32?
		public var sourceCount: UInt32?
		public var sourceXml: String?
		public var attributes: String?

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))OpenHomeProduct2ServiceState {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))manufacturerName: '\(manufacturerName ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))manufacturerInfo: '\(manufacturerInfo ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))manufacturerUrl: '\(manufacturerUrl ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))manufacturerImageUri: '\(manufacturerImageUri ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))modelName: '\(modelName ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))modelInfo: '\(modelInfo ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))modelUrl: '\(modelUrl ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))modelImageUri: '\(modelImageUri ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))productRoom: '\(productRoom ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))productName: '\(productName ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))productInfo: '\(productInfo ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))productUrl: '\(productUrl ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))productImageUri: '\(productImageUri ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))standby: \((standby == nil) ? "nil" : (standby! == true ? "true" : "false"))")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))sourceIndex: \(sourceIndex ?? 0)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))sourceCount: \(sourceCount ?? 0)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))sourceXml: '\(sourceXml ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))attributes: '\(attributes ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}

	public func state(xml: Data) throws -> State {
		struct PropertySet: Codable {
			var property: [State]
		}

		let decoder = XMLDecoder()
		decoder.shouldProcessNamespaces = true
		let propertySet = try decoder.decode(PropertySet.self, from: xml)

		return propertySet.property.reduce(State()) { partialResult, property in
			var result = partialResult
			if let manufacturerName = property.manufacturerName {
				result.manufacturerName = manufacturerName
			}
			if let manufacturerInfo = property.manufacturerInfo {
				result.manufacturerInfo = manufacturerInfo
			}
			if let manufacturerUrl = property.manufacturerUrl {
				result.manufacturerUrl = manufacturerUrl
			}
			if let manufacturerImageUri = property.manufacturerImageUri {
				result.manufacturerImageUri = manufacturerImageUri
			}
			if let modelName = property.modelName {
				result.modelName = modelName
			}
			if let modelInfo = property.modelInfo {
				result.modelInfo = modelInfo
			}
			if let modelUrl = property.modelUrl {
				result.modelUrl = modelUrl
			}
			if let modelImageUri = property.modelImageUri {
				result.modelImageUri = modelImageUri
			}
			if let productRoom = property.productRoom {
				result.productRoom = productRoom
			}
			if let productName = property.productName {
				result.productName = productName
			}
			if let productInfo = property.productInfo {
				result.productInfo = productInfo
			}
			if let productUrl = property.productUrl {
				result.productUrl = productUrl
			}
			if let productImageUri = property.productImageUri {
				result.productImageUri = productImageUri
			}
			if let standby = property.standby {
				result.standby = standby
			}
			if let sourceIndex = property.sourceIndex {
				result.sourceIndex = sourceIndex
			}
			if let sourceCount = property.sourceCount {
				result.sourceCount = sourceCount
			}
			if let sourceXml = property.sourceXml {
				result.sourceXml = sourceXml
			}
			if let attributes = property.attributes {
				result.attributes = attributes
			}
			return result
		}
	}

	public var stateSubject: AnyPublisher<State, Never> {
		subscribedEventPublisher
			.compactMap { [weak self] in
				guard let self else { return nil }

				return try? self.state(xml: $0)
			}
			.eraseToAnyPublisher()
	}

	public var stateChangeStream: AsyncStream<State> {
		stateSubject.stream
	}
}
