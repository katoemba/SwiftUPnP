import Foundation
import Combine
import XMLCoder
import os.log

public class OpenHomeConfig1Service: UPnPService {
	struct Envelope<T: Codable>: Codable {
		enum CodingKeys: String, CodingKey {
			case body = "s:Body"
		}

		var body: T
	}

	public struct GetKeysResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case keyList = "KeyList"
		}

		public var keyList: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetKeysResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))keyList: '\(keyList)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getKeys(log: UPnPService.MessageLog = .none) async throws -> GetKeysResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
			}

			@Attribute var urn: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetKeys"
				case response = "u:GetKeysResponse"
			}

			var action: SoapAction?
			var response: GetKeysResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetKeys", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

	public func setValue(key: String, value: String, log: UPnPService.MessageLog = .none) async throws {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case key = "Key"
				case value = "Value"
			}

			@Attribute var urn: String
			public var key: String
			public var value: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:SetValue"
			}

			var action: SoapAction
		}
		try await post(action: "SetValue", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), key: key, value: value))), log: log)
	}

	public struct GetValueResponse: Codable {
		enum CodingKeys: String, CodingKey {
			case value = "Value"
		}

		public var value: String

		public func log(deep: Bool = false, indent: Int = 0) {
			Logger.swiftUPnP.debug("\(Logger.indent(indent))GetValueResponse {")
			Logger.swiftUPnP.debug("\(Logger.indent(indent+1))value: '\(value)'")
			Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
		}
	}
	public func getValue(key: String, log: UPnPService.MessageLog = .none) async throws -> GetValueResponse {
		struct SoapAction: Codable {
			enum CodingKeys: String, CodingKey {
				case urn = "xmlns:u"
				case key = "Key"
			}

			@Attribute var urn: String
			public var key: String
		}
		struct Body: Codable {
			enum CodingKeys: String, CodingKey {
				case action = "u:GetValue"
				case response = "u:GetValueResponse"
			}

			var action: SoapAction?
			var response: GetValueResponse?
		}
		let result: Envelope<Body> = try await postWithResult(action: "GetValue", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), key: key))), log: log)

		guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
		return response
	}

}

