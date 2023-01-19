import Foundation
import Combine
import XMLCoder

public class OpenHomeProduct1Service: UPnPService {
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
	}
	public func manufacturer() async throws -> ManufacturerResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Manufacturer", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

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
	}
	public func model() async throws -> ModelResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Model", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

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
	}
	public func product() async throws -> ProductResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Product", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct StandbyResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func standby() async throws -> StandbyResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Standby", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setStandby(value: Bool) async throws {
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
		try await post(action: "SetStandby", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public struct SourceCountResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func sourceCount() async throws -> SourceCountResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "SourceCount", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceXmlResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String
	}
	public func sourceXml() async throws -> SourceXmlResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "SourceXml", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceIndexResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func sourceIndex() async throws -> SourceIndexResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "SourceIndex", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setSourceIndex(value: UInt32) async throws {
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
		try await post(action: "SetSourceIndex", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func setSourceIndexByName(value: String) async throws {
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
		try await post(action: "SetSourceIndexByName", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
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
	}
	public func source(index: UInt32) async throws -> SourceResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Source", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), index: index))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct AttributesResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String
	}
	public func attributes() async throws -> AttributesResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "Attributes", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SourceXmlChangeCountResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func sourceXmlChangeCount() async throws -> SourceXmlChangeCountResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "SourceXmlChangeCount", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeProduct1Service {
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
}
