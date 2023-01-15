import Foundation
import Combine
import XMLCoder

public class OpenHomeRadio1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public enum TransportStateEnum: String, Codable {
		case stopped = "Stopped"
		case playing = "Playing"
		case paused = "Paused"
		case buffering = "Buffering"
	}

	public func play() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Play"
			}

			var action: SoapAction
		}
		try await post(action: "Play", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func pause() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Pause"
			}

			var action: SoapAction
		}
		try await post(action: "Pause", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func stop() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Stop"
			}

			var action: SoapAction
		}
		try await post(action: "Stop", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func seekSecondAbsolute(value: UInt32) async throws {
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
				case action = "u:SeekSecondAbsolute"
			}

			var action: SoapAction
		}
		try await post(action: "SeekSecondAbsolute", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func seekSecondRelative(value: Int32) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
			}

			@Attribute var urn: String
			public var value: Int32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SeekSecondRelative"
			}

			var action: SoapAction
		}
		try await post(action: "SeekSecondRelative", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public struct ChannelResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case uri = "Uri"
			case metadata = "Metadata"
		}

		public var uri: String
		public var metadata: String
	}
	public func channel() async throws -> ChannelResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Channel"
			}

			var action: SoapAction?
			var response: ChannelResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Channel", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setChannel(uri: String, metadata: String) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case uri = "Uri"
				case metadata = "Metadata"
			}

			@Attribute var urn: String
			public var uri: String
			public var metadata: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetChannel"
			}

			var action: SoapAction
		}
		try await post(action: "SetChannel", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), uri: uri, metadata: metadata))))
	}

	public struct TransportStateResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: TransportStateEnum
	}
	public func transportState() async throws -> TransportStateResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:TransportState"
			}

			var action: SoapAction?
			var response: TransportStateResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "TransportState", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct IdResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func id() async throws -> IdResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Id"
			}

			var action: SoapAction?
			var response: IdResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Id", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setId(value: UInt32, uri: String) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case value = "Value"
				case uri = "Uri"
			}

			@Attribute var urn: String
			public var value: UInt32
			public var uri: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetId"
			}

			var action: SoapAction
		}
		try await post(action: "SetId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value, uri: uri))))
	}

	public struct ReadResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case metadata = "Metadata"
		}

		public var metadata: String
	}
	public func read(id: UInt32) async throws -> ReadResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
			}

			@Attribute var urn: String
			public var id: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Read"
			}

			var action: SoapAction?
			var response: ReadResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Read", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ReadListResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case channelList = "ChannelList"
		}

		public var channelList: String
	}
	public func readList(idList: String) async throws -> ReadListResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case idList = "IdList"
			}

			@Attribute var urn: String
			public var idList: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ReadList"
			}

			var action: SoapAction?
			var response: ReadListResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ReadList", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), idList: idList))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct IdArrayResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case token = "Token"
			case arrayData = "Array"
		}

		public var token: UInt32
		public var arrayData: Data?
		public var array: [UInt32]? {
			arrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
	}
	public func idArray() async throws -> IdArrayResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:IdArray"
			}

			var action: SoapAction?
			var response: IdArrayResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "IdArray", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct IdArrayChangedResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func idArrayChanged(token: UInt32) async throws -> IdArrayChangedResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case token = "Token"
			}

			@Attribute var urn: String
			public var token: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:IdArrayChanged"
			}

			var action: SoapAction?
			var response: IdArrayChangedResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "IdArrayChanged", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), token: token))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ChannelsMaxResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func channelsMax() async throws -> ChannelsMaxResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ChannelsMax"
			}

			var action: SoapAction?
			var response: ChannelsMaxResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ChannelsMax", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ProtocolInfoResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String
	}
	public func protocolInfo() async throws -> ProtocolInfoResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ProtocolInfo"
			}

			var action: SoapAction?
			var response: ProtocolInfoResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ProtocolInfo", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeRadio1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case uri = "Uri"
			case metadata = "Metadata"
			case transportState = "TransportState"
			case id = "Id"
			case idArrayData = "IdArray"
			case channelsMax = "ChannelsMax"
			case protocolInfo = "ProtocolInfo"
		}

		public var uri: String?
		public var metadata: String?
		public var transportState: TransportStateEnum?
		public var id: UInt32?
		public var idArrayData: Data?
		public var idArray: [UInt32]? {
			idArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var channelsMax: UInt32?
		public var protocolInfo: String?
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
			if let uri = property.uri {
				result.uri = uri
			}
			if let metadata = property.metadata {
				result.metadata = metadata
			}
			if let transportState = property.transportState {
				result.transportState = transportState
			}
			if let id = property.id {
				result.id = id
			}
			if let idArrayData = property.idArrayData {
				result.idArrayData = idArrayData
			}
			if let channelsMax = property.channelsMax {
				result.channelsMax = channelsMax
			}
			if let protocolInfo = property.protocolInfo {
				result.protocolInfo = protocolInfo
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
