import Foundation
import Combine
import XMLCoder

public class OpenHomeVolume1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct CharacteristicsResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case volumeMax = "VolumeMax"
			case volumeUnity = "VolumeUnity"
			case volumeSteps = "VolumeSteps"
			case volumeMilliDbPerStep = "VolumeMilliDbPerStep"
			case balanceMax = "BalanceMax"
			case fadeMax = "FadeMax"
		}

		public var volumeMax: UInt32
		public var volumeUnity: UInt32
		public var volumeSteps: UInt32
		public var volumeMilliDbPerStep: UInt32
		public var balanceMax: UInt32
		public var fadeMax: UInt32
	}
	public func characteristics() async throws -> CharacteristicsResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Characteristics"
			}

			var action: SoapAction?
			var response: CharacteristicsResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Characteristics", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setVolume(value: UInt32) async throws {
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
				case action = "u:SetVolume"
			}

			var action: SoapAction
		}
		try await post(action: "SetVolume", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func volumeInc() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:VolumeInc"
			}

			var action: SoapAction
		}
		try await post(action: "VolumeInc", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func volumeDec() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:VolumeDec"
			}

			var action: SoapAction
		}
		try await post(action: "VolumeDec", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public struct VolumeResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func volume() async throws -> VolumeResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Volume"
			}

			var action: SoapAction?
			var response: VolumeResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Volume", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setBalance(value: Int32) async throws {
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
				case action = "u:SetBalance"
			}

			var action: SoapAction
		}
		try await post(action: "SetBalance", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func balanceInc() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:BalanceInc"
			}

			var action: SoapAction
		}
		try await post(action: "BalanceInc", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func balanceDec() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:BalanceDec"
			}

			var action: SoapAction
		}
		try await post(action: "BalanceDec", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public struct BalanceResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Int32
	}
	public func balance() async throws -> BalanceResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Balance"
			}

			var action: SoapAction?
			var response: BalanceResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Balance", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setFade(value: Int32) async throws {
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
				case action = "u:SetFade"
			}

			var action: SoapAction
		}
		try await post(action: "SetFade", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public func fadeInc() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:FadeInc"
			}

			var action: SoapAction
		}
		try await post(action: "FadeInc", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public func fadeDec() async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:FadeDec"
			}

			var action: SoapAction
		}
		try await post(action: "FadeDec", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))
	}

	public struct FadeResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Int32
	}
	public func fade() async throws -> FadeResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Fade"
			}

			var action: SoapAction?
			var response: FadeResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Fade", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setMute(value: Bool) async throws {
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
				case action = "u:SetMute"
			}

			var action: SoapAction
		}
		try await post(action: "SetMute", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), value: value))))
	}

	public struct MuteResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: Bool
	}
	public func mute() async throws -> MuteResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Mute"
			}

			var action: SoapAction?
			var response: MuteResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Mute", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct VolumeLimitResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: UInt32
	}
	public func volumeLimit() async throws -> VolumeLimitResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:VolumeLimit"
			}

			var action: SoapAction?
			var response: VolumeLimitResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "VolumeLimit", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeVolume1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case volume = "Volume"
			case mute = "Mute"
			case balance = "Balance"
			case fade = "Fade"
			case volumeLimit = "VolumeLimit"
			case volumeMax = "VolumeMax"
			case volumeUnity = "VolumeUnity"
			case volumeSteps = "VolumeSteps"
			case volumeMilliDbPerStep = "VolumeMilliDbPerStep"
			case balanceMax = "BalanceMax"
			case fadeMax = "FadeMax"
		}

		public var volume: UInt32?
		public var mute: Bool?
		public var balance: Int32?
		public var fade: Int32?
		public var volumeLimit: UInt32?
		public var volumeMax: UInt32?
		public var volumeUnity: UInt32?
		public var volumeSteps: UInt32?
		public var volumeMilliDbPerStep: UInt32?
		public var balanceMax: UInt32?
		public var fadeMax: UInt32?
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
			if let volume = property.volume {
				result.volume = volume
			}
			if let mute = property.mute {
				result.mute = mute
			}
			if let balance = property.balance {
				result.balance = balance
			}
			if let fade = property.fade {
				result.fade = fade
			}
			if let volumeLimit = property.volumeLimit {
				result.volumeLimit = volumeLimit
			}
			if let volumeMax = property.volumeMax {
				result.volumeMax = volumeMax
			}
			if let volumeUnity = property.volumeUnity {
				result.volumeUnity = volumeUnity
			}
			if let volumeSteps = property.volumeSteps {
				result.volumeSteps = volumeSteps
			}
			if let volumeMilliDbPerStep = property.volumeMilliDbPerStep {
				result.volumeMilliDbPerStep = volumeMilliDbPerStep
			}
			if let balanceMax = property.balanceMax {
				result.balanceMax = balanceMax
			}
			if let fadeMax = property.fadeMax {
				result.fadeMax = fadeMax
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
