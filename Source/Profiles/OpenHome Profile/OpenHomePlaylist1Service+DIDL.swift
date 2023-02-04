//
//  OpenHomePlaylist1Service+DIDL.swift
//
//  Copyright (c) 2023 Katoemba Software, (https://rigelian.net/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Berrie Kremers on 15/01/2023.
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
