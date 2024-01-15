//
//  ContentDirectory1Service+DIDL.swift
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

public struct DIDLLite: Codable {
    public init(container: [DIDLContainer], item: [DIDLItem], desc: [DIDLDescription]) {
        self.container = container
        self.item = item
        self.desc = desc
    }
    
    public let container: [DIDLContainer]
    public let item: [DIDLItem]
    public let desc: [DIDLDescription]
    
    public static func from(_ metadata: String) -> DIDLLite? {
        guard let data = metadata.data(using: .utf8) else { return nil }
        
        do {
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = false
            
            return try decoder.decode(DIDLLite.self, from: data)
        }
        catch DecodingError.dataCorrupted(let context) {
            Logger.swiftUPnP.error("\(metadata)")
            Logger.swiftUPnP.error("\(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            Logger.swiftUPnP.error("\(metadata)")
            Logger.swiftUPnP.error("\(key.stringValue) was not found, \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            Logger.swiftUPnP.error("\(metadata)")
            Logger.swiftUPnP.error("\(type) was expected, \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            Logger.swiftUPnP.error("\(metadata)")
            Logger.swiftUPnP.error("no value was found for \(type), \(context.debugDescription)")
        } catch {
            Logger.swiftUPnP.error("\(metadata)")
            Logger.swiftUPnP.error("Unknown error \(error.localizedDescription)")
        }
        
        return nil
    }
    
    public static func firstItem(_ metadata: String) -> DIDLItem? {
        guard let didl = from(metadata) else { return nil }
        guard didl.item.count > 0 else { return nil }
        
        return didl.item[0]
    }
}

public struct DIDLContainer: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case parentID
        case childCount
        case restricted
        case searchable

        case container
        case item
        case desc
        case res

        case `class` = "upnp:class"
        case title = "dc:title"
        case creator = "dc:creator"
        case date = "dc:date"
        case artist = "upnp:artist"
        case genre = "upnp:genre"
        case albumArtURI = "upnp:albumArtURI"
        case artistDiscographyURI = "upnp:artistDiscographyURI"
        case lyricsURI = "upnp:URI"
    }

    @Attribute public var id: String
    @Attribute public var parentID: String
    @Attribute public var childCount: Int?
    @Attribute public var restricted: Bool
    @Attribute public var searchable: Bool?
    
    public let container: [DIDLContainer]
    public let item: [DIDLItem]
    public let desc: [DIDLDescription]
    public let res: [DIDLRes]

    public let `class`: String
    public let title: String
    public let creator: String?
    public let date: String?
    public let artist: [DIDLArtist]
    public let genre: String?
    public let albumArtURI: [URL]
    public let artistDiscographyURI: URL?
    public let lyricsURI: URL?
}

public struct DIDLItem: Codable, DynamicNodeDecoding, DynamicNodeEncoding {
    public init(id: String? = nil,
                refID: String? = nil,
                parentID: String? = nil,
                restricted: Bool? = nil,
                searchable: Bool? = nil,
                res: [DIDLRes],
                desc: [DIDLDescription],
                `class`: String,
                title: String,
                orig: String? = nil,
                date: String? = nil,
                album: String? = nil,
                artist: [DIDLArtist],
                genre: String? = nil,
                playlist: String? = nil,
                albumArtURI: [URL],
                artistDiscographyURI: URL? = nil,
                lyricsURI: URL? = nil,
                originalTrackNumber: UInt32? = nil,
                originalDiscNumber: UInt32? = nil) {
        self.res = res
        self.desc = desc
        self.`class` = `class`
        self.title = title
        self.orig = orig
        self.date = date
        self.album = album
        self.artist = artist
        self.genre = genre
        self.playlist = playlist
        self.albumArtURI = albumArtURI
        self.artistDiscographyURI = artistDiscographyURI
        self.lyricsURI = lyricsURI
        self.originalTrackNumber = originalTrackNumber
        self.originalDiscNumber = originalDiscNumber
        self.id = id
        self.refID = refID
        self.parentID = parentID
        self.restricted = restricted
        self.searchable = searchable
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case refID
        case parentID
        case restricted
        case searchable
        
        case res
        case desc

        case `class` = "upnp:class"
        case title = "dc:title"
        case orig = "upnp:orig"
        case date = "dc:date"
        case album = "upnp:album"
        case artist = "upnp:artist"
        case genre = "upnp:genre"
        case playlist = "upnp:playlist"
        case albumArtURI = "upnp:albumArtURI"
        case artistDiscographyURI = "upnp:artistDiscographyURI"
        case lyricsURI = "upnp:URI"
        case originalTrackNumber = "upnp:originalTrackNumber"
        case originalDiscNumber = "upnp:originalDiscNumber"
    }

    public let id: String?
    public let refID: String?
    public let parentID: String?
    public let restricted: Bool?
    public let searchable: Bool?

    public let res: [DIDLRes]
    public let desc: [DIDLDescription]

    public let `class`: String
    public let title: String
    public let orig: String?
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
    
    static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.id, CodingKeys.refID, CodingKeys.parentID, CodingKeys.restricted, CodingKeys.searchable:
            return .attribute
        default:
            return .element
        }
    }

    static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.id, CodingKeys.refID, CodingKeys.parentID, CodingKeys.restricted, CodingKeys.searchable:
            return .attribute
        default:
            return .element
        }
    }

}

public struct DIDLDescription: Codable, DynamicNodeDecoding {
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case nameSpace
        case value = ""
    }

    public let id: String
    public let type: String?
    public let nameSpace: URL
    public let value: String
    
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
public struct DIDLRes: Codable, DynamicNodeDecoding, DynamicNodeEncoding {
    public init(importUri: URL? = nil,
                protocolInfo: String? = nil,
                size: UInt64? = nil, duration:
                String? = nil,
                bitrate: UInt? = nil,
                sampleFrequency: UInt? = nil,
                bitsPerSample: UInt? = nil,
                nrAudioChannels: UInt? = nil,
                colorDepth: UInt? = nil,
                protection: String? = nil,
                resolution: String? = nil,
                value: URL) {
        self.importUri = importUri
        self.protocolInfo = protocolInfo
        self.size = size
        self.duration = duration
        self.bitrate = bitrate
        self.sampleFrequency = sampleFrequency
        self.bitsPerSample = bitsPerSample
        self.nrAudioChannels = nrAudioChannels
        self.colorDepth = colorDepth
        self.protection = protection
        self.resolution = resolution
        self.value = value
    }
    
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
    public let protocolInfo: String?
    public let size: UInt64?
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
    
    static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.value:
            return .element
        default:
            return .attribute
        }
    }
}

// Combination of value with attributes doesn't work (yet) with XMLCoder, revert to DynamicNodeDecoding
public struct DIDLArtist: Codable, DynamicNodeDecoding, DynamicNodeEncoding {
    public init(role: String? = nil, value: String) {
        self.role = role
        self.value = value
    }
    
    enum CodingKeys: String, CodingKey {
        case role
        case value = ""
    }
    
    public let role: String?
    public let value: String
    
    static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.value:
            return .element
        default:
            return .attribute
        }
    }
    
    static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
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
        decoder.shouldProcessNamespaces = false
        
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
        decoder.shouldProcessNamespaces = false
        
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
