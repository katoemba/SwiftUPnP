import Foundation
import Combine
import XMLCoder

public class ContentDirectory1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public enum A_ARG_TYPE_BrowseFlagEnum: String, Codable {
		case browseMetadata = "BrowseMetadata"
		case browseDirectChildren = "BrowseDirectChildren"
	}

	public struct BrowseResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case result = "Result"
			case numberReturned = "NumberReturned"
			case totalMatches = "TotalMatches"
			case updateID = "UpdateID"
		}

		public var result: String
		public var numberReturned: UInt32
		public var totalMatches: UInt32
		public var updateID: UInt32
	}
	public func browse(objectID: String, browseFlag: A_ARG_TYPE_BrowseFlagEnum, filter: String, startingIndex: UInt32, requestedCount: UInt32, sortCriteria: String) async throws -> BrowseResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case objectID = "ObjectID"
				case browseFlag = "BrowseFlag"
				case filter = "Filter"
				case startingIndex = "StartingIndex"
				case requestedCount = "RequestedCount"
				case sortCriteria = "SortCriteria"
			}

			@Attribute var urn: String
			public var objectID: String
			public var browseFlag: A_ARG_TYPE_BrowseFlagEnum
			public var filter: String
			public var startingIndex: UInt32
			public var requestedCount: UInt32
			public var sortCriteria: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Browse"
				case response = "u:BrowseResponse"
			}

			var action: SoapAction?
			var response: BrowseResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Browse", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), objectID: objectID, browseFlag: browseFlag, filter: filter, startingIndex: startingIndex, requestedCount: requestedCount, sortCriteria: sortCriteria))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetSortCapabilitiesResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case sortCaps = "SortCaps"
		}

		public var sortCaps: String
	}
	public func getSortCapabilities() async throws -> GetSortCapabilitiesResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetSortCapabilities"
				case response = "u:GetSortCapabilitiesResponse"
			}

			var action: SoapAction?
			var response: GetSortCapabilitiesResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetSortCapabilities", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetSystemUpdateIDResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
		}

		public var id: UInt32
	}
	public func getSystemUpdateID() async throws -> GetSystemUpdateIDResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetSystemUpdateID"
				case response = "u:GetSystemUpdateIDResponse"
			}

			var action: SoapAction?
			var response: GetSystemUpdateIDResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetSystemUpdateID", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetSearchCapabilitiesResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case searchCaps = "SearchCaps"
		}

		public var searchCaps: String
	}
	public func getSearchCapabilities() async throws -> GetSearchCapabilitiesResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetSearchCapabilities"
				case response = "u:GetSearchCapabilitiesResponse"
			}

			var action: SoapAction?
			var response: GetSearchCapabilitiesResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetSearchCapabilities", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct SearchResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case result = "Result"
			case numberReturned = "NumberReturned"
			case totalMatches = "TotalMatches"
			case updateID = "UpdateID"
		}

		public var result: String
		public var numberReturned: UInt32
		public var totalMatches: UInt32
		public var updateID: UInt32
	}
	public func search(containerID: String, searchCriteria: String, filter: String, startingIndex: UInt32, requestedCount: UInt32, sortCriteria: String) async throws -> SearchResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case containerID = "ContainerID"
				case searchCriteria = "SearchCriteria"
				case filter = "Filter"
				case startingIndex = "StartingIndex"
				case requestedCount = "RequestedCount"
				case sortCriteria = "SortCriteria"
			}

			@Attribute var urn: String
			public var containerID: String
			public var searchCriteria: String
			public var filter: String
			public var startingIndex: UInt32
			public var requestedCount: UInt32
			public var sortCriteria: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Search"
				case response = "u:SearchResponse"
			}

			var action: SoapAction?
			var response: SearchResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Search", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), containerID: containerID, searchCriteria: searchCriteria, filter: filter, startingIndex: startingIndex, requestedCount: requestedCount, sortCriteria: sortCriteria))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension ContentDirectory1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case containerUpdateIDs = "ContainerUpdateIDs"
			case systemUpdateID = "SystemUpdateID"
		}

		public var containerUpdateIDs: String?
		public var systemUpdateID: UInt32?
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
			if let containerUpdateIDs = property.containerUpdateIDs {
				result.containerUpdateIDs = containerUpdateIDs
			}
			if let systemUpdateID = property.systemUpdateID {
				result.systemUpdateID = systemUpdateID
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
