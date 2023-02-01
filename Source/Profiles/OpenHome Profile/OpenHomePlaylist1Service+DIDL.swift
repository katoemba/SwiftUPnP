//
// Package: SwiftUPnP
//
// Created by Berrie Kremers on 01/02/2023
// Copyright © 2018-2023 Katoemba Software. All rights reserved.
//
	

import Foundation
import XMLCoder
import os.log


public struct ReadListDIDLResponse {
    public struct Track {
        public let id: UInt32
        public let uri: String
        public let didl: DIDLLite
    }
    public let tracks: [Track]
}
public extension OpenHomePlaylist1Service {
    struct TrackList: Decodable {
        enum CodingKeys: String, CodingKey {
            case entry = "Entry"
        }
        let entry: [Entry]
    }
    struct Entry: Decodable {
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case uri = "Uri"
            case metadata = "Metadata"
        }
        let id: UInt32
        let uri: String
        let metadata: String
    }

    func readListDIDL(idList: String) async throws -> ReadListDIDLResponse {
        struct TrackList: Decodable {
            enum CodingKeys: String, CodingKey {
                case entry = "Entry"
            }
            let entry: [Entry]
        }
        struct Entry: Decodable {
            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case uri = "Uri"
                case metadata = "Metadata"
            }
            let id: UInt32
            let uri: String
            let metadata: String
        }
        let readListResponse = try await readList(idList: idList)
        
        guard let trackListData = readListResponse.trackList.data(using: .utf8) else {
            throw ServiceParseError.noValidResponse
        }
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        let trackList = try XMLDecoder().decode(TrackList.self, from: trackListData)
            
        return ReadListDIDLResponse(tracks: try trackList.entry.map {
            guard let data = $0.metadata.data(using: .utf8) else {
                throw ServiceParseError.noValidResponse
            }
            decoder.shouldProcessNamespaces = false
            let didl = try decoder.decode(DIDLLite.self, from: data)

            return ReadListDIDLResponse.Track(id: $0.id, uri: $0.uri, didl: didl)
        })
    }
}
