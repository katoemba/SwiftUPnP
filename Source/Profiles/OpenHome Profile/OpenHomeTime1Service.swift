import Foundation
import Combine
import XMLCoder

public class OpenHomeTime1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct TimeResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case trackCount = "TrackCount"
			case duration = "Duration"
			case seconds = "Seconds"
		}

		public var trackCount: UInt32
		public var duration: UInt32
		public var seconds: UInt32
	}
	public func time() async throws -> TimeResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Time"
			}

			var action: SoapAction?
			var response: TimeResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Time", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeTime1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case trackCount = "TrackCount"
			case duration = "Duration"
			case seconds = "Seconds"
		}

		public var trackCount: UInt32?
		public var duration: UInt32?
		public var seconds: UInt32?
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
			if let trackCount = property.trackCount {
				result.trackCount = trackCount
			}
			if let duration = property.duration {
				result.duration = duration
			}
			if let seconds = property.seconds {
				result.seconds = seconds
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
