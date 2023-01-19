import Foundation
import Combine
import XMLCoder

public class OpenHomePlaylist1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public enum TransportStateEnum: String, Codable {
		case playing = "Playing"
		case paused = "Paused"
		case stopped = "Stopped"
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

	public func next() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Next"
			}

			var action: SoapAction
		}
		try await post(action: "Next", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func previous() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Previous"
			}

			var action: SoapAction
		}
		try await post(action: "Previous", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func setRepeat(value: Bool) async throws {
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
				case action = "u:SetRepeat"
			}

			var action: SoapAction
		}
		try await post(action: "SetRepeat", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public struct RepeatResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func `repeat`() async throws -> RepeatResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Repeat"
				case response = "u:RepeatResponse"
			}

			var action: SoapAction?
			var response: RepeatResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Repeat", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setShuffle(value: Bool) async throws {
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
				case action = "u:SetShuffle"
			}

			var action: SoapAction
		}
		try await post(action: "SetShuffle", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public struct ShuffleResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func shuffle() async throws -> ShuffleResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Shuffle"
				case response = "u:ShuffleResponse"
			}

			var action: SoapAction?
			var response: ShuffleResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Shuffle", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
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

	public func seekId(value: UInt32) async throws {
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
				case action = "u:SeekId"
			}

			var action: SoapAction
		}
		try await post(action: "SeekId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func seekIndex(value: UInt32) async throws {
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
				case action = "u:SeekIndex"
			}

			var action: SoapAction
		}
		try await post(action: "SeekIndex", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
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
				case response = "u:TransportStateResponse"
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
				case response = "u:IdResponse"
			}

			var action: SoapAction?
			var response: IdResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Id", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ReadResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case uri = "Uri"
			case metadata = "Metadata"
		}

		public var uri: String
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
				case response = "u:ReadResponse"
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
			case trackList = "TrackList"
		}

		public var trackList: String
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
				case response = "u:ReadListResponse"
			}

			var action: SoapAction?
			var response: ReadListResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ReadList", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), idList: idList))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct InsertResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case newId = "NewId"
		}

		public var newId: UInt32
	}
	public func insert(afterId: UInt32, uri: String, metadata: String) async throws -> InsertResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case afterId = "AfterId"
				case uri = "Uri"
				case metadata = "Metadata"
			}

			@Attribute var urn: String
			public var afterId: UInt32
			public var uri: String
			public var metadata: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Insert"
				case response = "u:InsertResponse"
			}

			var action: SoapAction?
			var response: InsertResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Insert", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), afterId: afterId, uri: uri, metadata: metadata))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func deleteId(value: UInt32) async throws {
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
				case action = "u:DeleteId"
			}

			var action: SoapAction
		}
		try await post(action: "DeleteId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func deleteAll() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:DeleteAll"
			}

			var action: SoapAction
		}
		try await post(action: "DeleteAll", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public struct TracksMaxResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func tracksMax() async throws -> TracksMaxResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:TracksMax"
				case response = "u:TracksMaxResponse"
			}

			var action: SoapAction?
			var response: TracksMaxResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "TracksMax", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

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
				case response = "u:IdArrayResponse"
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
				case response = "u:IdArrayChangedResponse"
			}

			var action: SoapAction?
			var response: IdArrayChangedResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "IdArrayChanged", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), token: token))))

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
				case response = "u:ProtocolInfoResponse"
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
extension OpenHomePlaylist1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case transportState = "TransportState"
			case `repeat` = "Repeat"
			case shuffle = "Shuffle"
			case id = "Id"
			case idArrayData = "IdArray"
			case tracksMax = "TracksMax"
			case protocolInfo = "ProtocolInfo"
		}

		public var transportState: TransportStateEnum?
		public var `repeat`: Bool?
		public var shuffle: Bool?
		public var id: UInt32?
		public var idArrayData: Data?
		public var idArray: [UInt32]? {
			idArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var tracksMax: UInt32?
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
			if let transportState = property.transportState {
				result.transportState = transportState
			}
			if let `repeat` = property.`repeat` {
				result.`repeat` = `repeat`
			}
			if let shuffle = property.shuffle {
				result.shuffle = shuffle
			}
			if let id = property.id {
				result.id = id
			}
			if let idArrayData = property.idArrayData {
				result.idArrayData = idArrayData
			}
			if let tracksMax = property.tracksMax {
				result.tracksMax = tracksMax
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
