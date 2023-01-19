//
//  StorageFolder.swift
//
//
//  Created by Berrie Kremers on 15/01/2023.
//

import Foundation
import XMLCoder

public struct DIDLLite: Codable {
    public var container: [DIDLContainer]
    public var item: [DIDLItem]
}

public struct DIDLContainer: Codable {
    @Attribute public var id: String
    @Attribute public var parentID: String
    @Attribute public var childCount: Int?
    @Attribute public var restricted: Bool
    @Attribute public var searchable: Bool?
    
    public let `class`: String
    public let title: String
    public let creator: String?
    public let date: String?
    public let artist: [DIDLArtist]
    public let genre: String?
    public let albumArtURI: [URL]
    public let artistDiscographyURI: URL?
    public let lyricsURI: URL?
    public let res: [DIDLRes]
}

public struct DIDLItem: Codable {
    @Attribute public var id: String
    @Attribute public var refID: String?
    @Attribute public var parentID: String
    @Attribute public var restricted: Bool

    public let `class`: String
    public let title: String
    public let date: String?
    public let album: String?
    public let artist: [DIDLArtist]
    public let genre: String?
    public let playlist: String?
    public let albumArtURI: [URL]
    public let artistDiscographyURI: URL?
    public let lyricsURI: URL?
    public let originalTrackNumber: UInt32?
    public let originalDiscNumber: UInt32?
    public let res: [DIDLRes]
}

// Combination of value with attributes doesn't work (yet) with XMLCoder, revert to DynamicNodeDecoding
public struct DIDLRes: Codable, DynamicNodeDecoding {
    enum CodingKeys: String, CodingKey {
        case importUri
        case protocolInfo
        case size
        case duration
        case bitrate
        case sampleFrequency
        case bitsPerSample
        case nrAudioChannels
        case colorDepth
        case protection
        case resolution
        case value = ""
    }

    public let importUri: URL?
    public let protocolInfo: String
    public let size: UInt32?
    public let duration: String?
    public let bitrate: UInt?
    public let sampleFrequency: UInt?
    public let bitsPerSample: UInt?
    public let nrAudioChannels: UInt?
    public let colorDepth: UInt?
    public let protection: String?
    public let resolution: String?
    
    public let value: URL
    
    static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.value:
            return .element
        default:
            return .attribute
        }
    }

}

// Combination of value with attributes doesn't work (yet) with XMLCoder, revert to DynamicNodeDecoding
public struct DIDLArtist: Codable, DynamicNodeDecoding {
    enum CodingKeys: String, CodingKey {
        case role
        case value = ""
    }

    public let role: String?
    public var value: String
    
    static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.value:
            return .element
        default:
            return .attribute
        }
    }
}


public struct BrowseDIDLResponse {
    public let container: [DIDLContainer]
    public let item: [DIDLItem]

    public let numberReturned: UInt32
    public let totalMatches: UInt32
    public let updateID: UInt32
}
public struct SearchDIDLResponse {
    public let container: [DIDLContainer]
    public let item: [DIDLItem]

    public let numberReturned: UInt32
    public let totalMatches: UInt32
    public let updateID: UInt32
}
public extension ContentDirectory1Service {
    func browseDIDL(objectID: String, browseFlag: A_ARG_TYPE_BrowseFlagEnum, filter: String, startingIndex: UInt32, requestedCount: UInt32, sortCriteria: String) async throws -> BrowseDIDLResponse {
        let response = try await browse(objectID: objectID,
                                        browseFlag: browseFlag,
                                        filter: filter,
                                        startingIndex: startingIndex,
                                        requestedCount: requestedCount,
                                        sortCriteria: sortCriteria)
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        
        guard let data = response.result.data(using: .utf8) else {
            throw ServiceParseError.noValidResponse
        }
        let didl = try decoder.decode(DIDLLite.self, from: data)
        
        return BrowseDIDLResponse(container: didl.container,
                                  item: didl.item,
                                  numberReturned: response.numberReturned,
                                  totalMatches: response.totalMatches,
                                  updateID: response.updateID)
    }
    
    func searchDIDL(containerID: String, searchCriteria: String, filter: String, startingIndex: UInt32, requestedCount: UInt32, sortCriteria: String) async throws -> SearchDIDLResponse {
        let response = try await search(containerID: containerID,
                                        searchCriteria: searchCriteria,
                                        filter: filter,
                                        startingIndex: startingIndex,
                                        requestedCount: requestedCount,
                                        sortCriteria: sortCriteria)
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        
        guard let data = response.result.data(using: .utf8) else {
            throw ServiceParseError.noValidResponse
        }
        let didl = try decoder.decode(DIDLLite.self, from: data)

        return SearchDIDLResponse(container: didl.container,
                                  item: didl.item,
                                  numberReturned: response.numberReturned,
                                  totalMatches: response.totalMatches,
                                  updateID: response.updateID)

    }
}

