import Foundation
import Combine
import XMLCoder

public class OpenHomeCredentials1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public func set(id: String, userName: String, password: Data) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case userName = "UserName"
				case password = "Password"
			}

			@Attribute var urn: String
			public var id: String
			public var userName: String
			public var password: Data
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Set"
			}

			var action: SoapAction
		}
		try await post(action: "Set", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, userName: userName, password: password))))
	}

	public func clear(id: String) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
			}

			@Attribute var urn: String
			public var id: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Clear"
			}

			var action: SoapAction
		}
		try await post(action: "Clear", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))
	}

	public func setEnabled(id: String, enabled: Bool) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case enabled = "Enabled"
			}

			@Attribute var urn: String
			public var id: String
			public var enabled: Bool
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetEnabled"
			}

			var action: SoapAction
		}
		try await post(action: "SetEnabled", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, enabled: enabled))))
	}

	public struct GetResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case userName = "UserName"
			case passwordData = "Password"
			case enabled = "Enabled"
			case status = "Status"
			case data = "Data"
		}

		public var userName: String
		public var passwordData: Data?
		public var password: [UInt32]? {
			passwordData?.toArray(type: UInt32.self).map { $0.bigEndian }
		}
		public var enabled: Bool
		public var status: String
		public var data: String
	}
	public func get(id: String) async throws -> GetResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
			}

			@Attribute var urn: String
			public var id: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Get"
				case response = "u:GetResponse"
			}

			var action: SoapAction?
			var response: GetResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Get", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct LoginResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case token = "Token"
		}

		public var token: String
	}
	public func login(id: String) async throws -> LoginResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
			}

			@Attribute var urn: String
			public var id: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:Login"
				case response = "u:LoginResponse"
			}

			var action: SoapAction?
			var response: LoginResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "Login", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct ReLoginResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case newToken = "NewToken"
		}

		public var newToken: String
	}
	public func reLogin(id: String, currentToken: String) async throws -> ReLoginResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case id = "Id"
				case currentToken = "CurrentToken"
			}

			@Attribute var urn: String
			public var id: String
			public var currentToken: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ReLogin"
				case response = "u:ReLoginResponse"
			}

			var action: SoapAction?
			var response: ReLoginResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "ReLogin", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), id: id, currentToken: currentToken))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetIdsResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case ids = "Ids"
		}

		public var ids: String
	}
	public func getIds() async throws -> GetIdsResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetIds"
				case response = "u:GetIdsResponse"
			}

			var action: SoapAction?
			var response: GetIdsResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetIds", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetPublicKeyResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case publicKey = "PublicKey"
		}

		public var publicKey: String
	}
	public func getPublicKey() async throws -> GetPublicKeyResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetPublicKey"
				case response = "u:GetPublicKeyResponse"
			}

			var action: SoapAction?
			var response: GetPublicKeyResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetPublicKey", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetSequenceNumberResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case sequenceNumber = "SequenceNumber"
		}

		public var sequenceNumber: UInt32
	}
	public func getSequenceNumber() async throws -> GetSequenceNumberResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetSequenceNumber"
				case response = "u:GetSequenceNumberResponse"
			}

			var action: SoapAction?
			var response: GetSequenceNumberResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetSequenceNumber", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))))

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeCredentials1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case ids = "Ids"
			case publicKey = "PublicKey"
			case sequenceNumber = "SequenceNumber"
		}

		public var ids: String?
		public var publicKey: String?
		public var sequenceNumber: UInt32?
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
			if let ids = property.ids {
				result.ids = ids
			}
			if let publicKey = property.publicKey {
				result.publicKey = publicKey
			}
			if let sequenceNumber = property.sequenceNumber {
				result.sequenceNumber = sequenceNumber
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
