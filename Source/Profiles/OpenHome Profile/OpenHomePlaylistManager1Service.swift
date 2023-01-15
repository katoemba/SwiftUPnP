import Foundation
import Combine
import XMLCoder

public class OpenHomePlaylistManager1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct MetadataResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case metadata = "Metadata"
		}

		public var metadata: String
	}
	public func metadata() async throws -> MetadataResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Metadata"
			}

			var action: SoapAction?
			var response: MetadataResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Metadata", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ImagesXmlResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case imagesXml = "ImagesXml"
		}

		public var imagesXml: String
	}
	public func imagesXml() async throws -> ImagesXmlResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ImagesXml"
			}

			var action: SoapAction?
			var response: ImagesXmlResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ImagesXml", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct PlaylistReadArrayResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case arrayData = "Array"
		}

		public var arrayData: Data?
		public var array: [UInt32]? {
			arrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
	}
	public func playlistReadArray(id: UInt32) async throws -> PlaylistReadArrayResponse {
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
				case action = "u:PlaylistReadArray"
			}

			var action: SoapAction?
			var response: PlaylistReadArrayResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistReadArray", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct PlaylistReadListResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case playlistList = "PlaylistList"
		}

		public var playlistList: String
	}
	public func playlistReadList(idList: String) async throws -> PlaylistReadListResponse {
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
				case action = "u:PlaylistReadList"
			}

			var action: SoapAction?
			var response: PlaylistReadListResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistReadList", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), idList: idList))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct PlaylistReadResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case name = "Name"
			case description = "Description"
			case imageId = "ImageId"
		}

		public var name: String
		public var description: String
		public var imageId: UInt32
	}
	public func playlistRead(id: UInt32) async throws -> PlaylistReadResponse {
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
				case action = "u:PlaylistRead"
			}

			var action: SoapAction?
			var response: PlaylistReadResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistRead", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func playlistSetName(id: UInt32, name: String) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case name = "Name"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var name: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistSetName"
			}

			var action: SoapAction
		}
		try await post(action: "PlaylistSetName", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, name: name))))
	}

	public func playlistSetDescription(id: UInt32, description: String) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case description = "Description"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var description: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistSetDescription"
			}

			var action: SoapAction
		}
		try await post(action: "PlaylistSetDescription", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, description: description))))
	}

	public func playlistSetImageId(id: UInt32, imageId: UInt32) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case imageId = "ImageId"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var imageId: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistSetImageId"
			}

			var action: SoapAction
		}
		try await post(action: "PlaylistSetImageId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, imageId: imageId))))
	}

	public struct PlaylistInsertResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case newId = "NewId"
		}

		public var newId: UInt32
	}
	public func playlistInsert(afterId: UInt32, name: String, description: String, imageId: UInt32) async throws -> PlaylistInsertResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case afterId = "AfterId"
				case name = "Name"
				case description = "Description"
				case imageId = "ImageId"
			}

			@Attribute var urn: String
			public var afterId: UInt32
			public var name: String
			public var description: String
			public var imageId: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistInsert"
			}

			var action: SoapAction?
			var response: PlaylistInsertResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistInsert", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), afterId: afterId, name: name, description: description, imageId: imageId))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func playlistDeleteId(value: UInt32) async throws {
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
				case action = "u:PlaylistDeleteId"
			}

			var action: SoapAction
		}
		try await post(action: "PlaylistDeleteId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func playlistMove(id: UInt32, afterId: UInt32) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case afterId = "AfterId"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var afterId: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistMove"
			}

			var action: SoapAction
		}
		try await post(action: "PlaylistMove", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, afterId: afterId))))
	}

	public struct PlaylistsMaxResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func playlistsMax() async throws -> PlaylistsMaxResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistsMax"
			}

			var action: SoapAction?
			var response: PlaylistsMaxResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistsMax", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
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
			}

			var action: SoapAction?
			var response: TracksMaxResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "TracksMax", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct PlaylistArraysResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case token = "Token"
			case idArrayData = "IdArray"
			case tokenArrayData = "TokenArray"
		}

		public var token: UInt32
		public var idArrayData: Data?
		public var idArray: [UInt32]? {
			idArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var tokenArrayData: Data?
		public var tokenArray: [UInt32]? {
			tokenArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
	}
	public func playlistArrays() async throws -> PlaylistArraysResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:PlaylistArrays"
			}

			var action: SoapAction?
			var response: PlaylistArraysResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistArrays", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct PlaylistArraysChangedResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func playlistArraysChanged(token: UInt32) async throws -> PlaylistArraysChangedResponse {
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
				case action = "u:PlaylistArraysChanged"
			}

			var action: SoapAction?
			var response: PlaylistArraysChangedResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "PlaylistArraysChanged", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), token: token))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ReadResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case metadata = "Metadata"
		}

		public var metadata: String
	}
	public func read(id: UInt32, trackId: UInt32) async throws -> ReadResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case trackId = "TrackId"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var trackId: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Read"
			}

			var action: SoapAction?
			var response: ReadResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Read", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, trackId: trackId))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ReadListResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case trackList = "TrackList"
		}

		public var trackList: String
	}
	public func readList(id: UInt32, trackIdList: String) async throws -> ReadListResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case trackIdList = "TrackIdList"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var trackIdList: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ReadList"
			}

			var action: SoapAction?
			var response: ReadListResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ReadList", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, trackIdList: trackIdList))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct InsertResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case newTrackId = "NewTrackId"
		}

		public var newTrackId: UInt32
	}
	public func insert(id: UInt32, afterTrackId: UInt32, udn: String, metadataId: String) async throws -> InsertResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case afterTrackId = "AfterTrackId"
				case udn = "Udn"
				case metadataId = "MetadataId"
			}

			@Attribute var urn: String
			public var id: UInt32
			public var afterTrackId: UInt32
			public var udn: String
			public var metadataId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Insert"
			}

			var action: SoapAction?
			var response: InsertResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Insert", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, afterTrackId: afterTrackId, udn: udn, metadataId: metadataId))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func deleteId(trackId: UInt32, value: UInt32) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case trackId = "TrackId"
				case value = "Value"
			}

			@Attribute var urn: String
			public var trackId: UInt32
			public var value: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:DeleteId"
			}

			var action: SoapAction
		}
		try await post(action: "DeleteId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), trackId: trackId, value: value))))
	}

	public func deleteAll(trackId: UInt32) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case trackId = "TrackId"
			}

			@Attribute var urn: String
			public var trackId: UInt32
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:DeleteAll"
			}

			var action: SoapAction
		}
		try await post(action: "DeleteAll", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), trackId: trackId))))
	}

}

// Event parser
extension OpenHomePlaylistManager1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case metadata = "Metadata"
			case imagesXml = "ImagesXml"
			case idArrayData = "IdArray"
			case tokenArrayData = "TokenArray"
			case playlistsMax = "PlaylistsMax"
			case tracksMax = "TracksMax"
		}

		public var metadata: String?
		public var imagesXml: String?
		public var idArrayData: Data?
		public var idArray: [UInt32]? {
			idArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var tokenArrayData: Data?
		public var tokenArray: [UInt32]? {
			tokenArrayData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var playlistsMax: UInt32?
		public var tracksMax: UInt32?
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
			if let metadata = property.metadata {
				result.metadata = metadata
			}
			if let imagesXml = property.imagesXml {
				result.imagesXml = imagesXml
			}
			if let idArrayData = property.idArrayData {
				result.idArrayData = idArrayData
			}
			if let tokenArrayData = property.tokenArrayData {
				result.tokenArrayData = tokenArrayData
			}
			if let playlistsMax = property.playlistsMax {
				result.playlistsMax = playlistsMax
			}
			if let tracksMax = property.tracksMax {
				result.tracksMax = tracksMax
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
