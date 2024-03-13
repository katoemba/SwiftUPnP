import Foundation
import Combine
import XMLCoder
import os.log

public class OpenHomeOAuth1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct GetJobUpdateIdResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case jobUpdateId = "JobUpdateId"
		}

		public var jobUpdateId: UInt32

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetJobUpdateIdResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))jobUpdateId: \(jobUpdateId)")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getJobUpdateId(serviceId: String, log: UPnPService.MessageLog = .none) async throws -> GetJobUpdateIdResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
			}

			@Attribute var urn: String
			public var serviceId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetJobUpdateId"
				case response = "u:GetJobUpdateIdResponse"
			}

			var action: SoapAction?
			var response: GetJobUpdateIdResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetJobUpdateId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetUpdateIdResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case updateId = "UpdateId"
		}

		public var updateId: UInt32

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetUpdateIdResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))updateId: \(updateId)")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getUpdateId(log: UPnPService.MessageLog = .none) async throws -> GetUpdateIdResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetUpdateId"
				case response = "u:GetUpdateIdResponse"
			}

			var action: SoapAction?
			var response: GetUpdateIdResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetUpdateId", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func clearLonglivedLivedToken(serviceId: String, tokenId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
				case tokenId = "TokenId"
			}

			@Attribute var urn: String
			public var serviceId: String
			public var tokenId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearLonglivedLivedToken"
			}

			var action: SoapAction
		}
		try await post(action: "ClearLonglivedLivedToken", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId, tokenId: tokenId))), log: log)
	}

	public struct GetServiceStatusResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case serviceStatusJson = "ServiceStatusJson"
		}

		public var serviceStatusJson: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetServiceStatusResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))serviceStatusJson: '\(serviceStatusJson)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getServiceStatus(log: UPnPService.MessageLog = .none) async throws -> GetServiceStatusResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetServiceStatus"
				case response = "u:GetServiceStatusResponse"
			}

			var action: SoapAction?
			var response: GetServiceStatusResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetServiceStatus", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func clearAllTokens(serviceId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
			}

			@Attribute var urn: String
			public var serviceId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearAllTokens"
			}

			var action: SoapAction
		}
		try await post(action: "ClearAllTokens", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId))), log: log)
	}

	public func clearToken(serviceId: String, tokenId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
				case tokenId = "TokenId"
			}

			@Attribute var urn: String
			public var serviceId: String
			public var tokenId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearToken"
			}

			var action: SoapAction
		}
		try await post(action: "ClearToken", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId, tokenId: tokenId))), log: log)
	}

	public func setToken(serviceId: String, tokenId: String, aesKeyRsaEncrypted: Data, initVectorRsaEncrypted: Data, tokenAesEncrypted: Data, isLongLived: Bool, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
				case tokenId = "TokenId"
				case aesKeyRsaEncrypted = "AesKeyRsaEncrypted"
				case initVectorRsaEncrypted = "InitVectorRsaEncrypted"
				case tokenAesEncrypted = "TokenAesEncrypted"
				case isLongLived = "IsLongLived"
			}

			@Attribute var urn: String
			public var serviceId: String
			public var tokenId: String
			public var aesKeyRsaEncrypted: Data
			public var initVectorRsaEncrypted: Data
			public var tokenAesEncrypted: Data
			public var isLongLived: Bool
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetToken"
			}

			var action: SoapAction
		}
		try await post(action: "SetToken", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId, tokenId: tokenId, aesKeyRsaEncrypted: aesKeyRsaEncrypted, initVectorRsaEncrypted: initVectorRsaEncrypted, tokenAesEncrypted: tokenAesEncrypted, isLongLived: isLongLived))), log: log)
	}

	public func clearShortLivedToken(serviceId: String, tokenId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
				case tokenId = "TokenId"
			}

			@Attribute var urn: String
			public var serviceId: String
			public var tokenId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearShortLivedToken"
			}

			var action: SoapAction
		}
		try await post(action: "ClearShortLivedToken", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId, tokenId: tokenId))), log: log)
	}

	public func clearLonglivedLivedTokens(serviceId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
			}

			@Attribute var urn: String
			public var serviceId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearLonglivedLivedTokens"
			}

			var action: SoapAction
		}
		try await post(action: "ClearLonglivedLivedTokens", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId))), log: log)
	}

	public struct BeginLimitedInputFlowResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case jobId = "JobId"
			case loginUrl = "LoginUrl"
			case userCode = "UserCode"
		}

		public var jobId: String
		public var loginUrl: String
		public var userCode: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))BeginLimitedInputFlowResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))jobId: '\(jobId)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))loginUrl: '\(loginUrl)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))userCode: '\(userCode)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func beginLimitedInputFlow(serviceId: String, log: UPnPService.MessageLog = .none) async throws -> BeginLimitedInputFlowResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
			}

			@Attribute var urn: String
			public var serviceId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:BeginLimitedInputFlow"
				case response = "u:BeginLimitedInputFlowResponse"
			}

			var action: SoapAction?
			var response: BeginLimitedInputFlowResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "BeginLimitedInputFlow", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetPublicKeyResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case publicKey = "PublicKey"
		}

		public var publicKey: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetPublicKeyResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))publicKey: '\(publicKey)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getPublicKey(log: UPnPService.MessageLog = .none) async throws -> GetPublicKeyResponse {
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
		let result: Envelope<Body> = try await postWithResult(action: "GetPublicKey", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public struct GetSupportedServicesResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case supportedServices = "SupportedServices"
		}

		public var supportedServices: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetSupportedServicesResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))supportedServices: '\(supportedServices)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getSupportedServices(log: UPnPService.MessageLog = .none) async throws -> GetSupportedServicesResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetSupportedServices"
				case response = "u:GetSupportedServicesResponse"
			}

			var action: SoapAction?
			var response: GetSupportedServicesResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetSupportedServices", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func clearShortLivedTokens(serviceId: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case serviceId = "ServiceId"
			}

			@Attribute var urn: String
			public var serviceId: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:ClearShortLivedTokens"
			}

			var action: SoapAction
		}
		try await post(action: "ClearShortLivedTokens", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), serviceId: serviceId))), log: log)
	}

	public struct GetJobStatusResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case jobStatusJson = "JobStatusJson"
		}

		public var jobStatusJson: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetJobStatusResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))jobStatusJson: '\(jobStatusJson)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getJobStatus(log: UPnPService.MessageLog = .none) async throws -> GetJobStatusResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetJobStatus"
				case response = "u:GetJobStatusResponse"
			}

			var action: SoapAction?
			var response: GetJobStatusResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetJobStatus", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

// Event parser
extension OpenHomeOAuth1Service {
	public struct State: Codable {
		enum CodingKeys: String, CodingKey {
			case publicKey = "PublicKey"
			case supportedServices = "SupportedServices"
			case updateId = "UpdateId"
		}

		public var publicKey: String?
		public var supportedServices: String?
		public var updateId: UInt32?

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))OpenHomeOAuth1ServiceState {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))publicKey: '\(publicKey ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))supportedServices: '\(supportedServices ?? "nil")'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))updateId: \(updateId ?? 0)'")
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
			if let publicKey = property.publicKey {
				result.publicKey = publicKey
			}
			if let supportedServices = property.supportedServices {
				result.supportedServices = supportedServices
			}
			if let updateId = property.updateId {
				result.updateId = updateId
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
