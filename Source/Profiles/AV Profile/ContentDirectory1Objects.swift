//
//  ContentDirectory1Object.swift
//
//  Copyright (c) 2015 David Robles
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

import Foundation
import Fuzi
import CoreGraphics

// MARK: ContentDirectory1Object

/// TODO: For now rooting to NSObject to expose to Objective-C, see Github issue #16
@objcMembers public class ContentDirectory1Object: NSObject {
    public let objectID: String
    public let parentID: String
    public let title: String
    public let rawType: String
    public let albumArtURL: URL?
    
    init?(xmlElement: Fuzi.XMLElement) {
        if let objectID = xmlElement.attr("id"),
            let parentID = xmlElement.attr("parentID"),
            let title = xmlElement.firstChild(tag: "title")?.stringValue,
            let rawType = xmlElement.firstChild(tag: "class")?.stringValue {
                self.objectID = objectID
                self.parentID = parentID
                self.title = title
                self.rawType = rawType
                
                if let albumArtURLString = xmlElement.firstChild(tag: "albumArtURI")?.stringValue {
                    self.albumArtURL = URL(string: albumArtURLString)
                } else { albumArtURL = nil }
        } else {
            /// TODO: Remove default initializations to simply return nil, see Github issue #11
            objectID = ""
            parentID = ""
            title = ""
            rawType = ""
            albumArtURL = nil
            super.init()
            return nil
        }
        
        super.init()
    }
}

// MARK: - ContentDirectory1Container

@objcMembers public class ContentDirectory1Container: ContentDirectory1Object {
    public let childCount: Int?
    
    override init?(xmlElement: Fuzi.XMLElement) {
        self.childCount = Int(String(describing: xmlElement.attr("childCount")))
        
        super.init(xmlElement: xmlElement)
    }
}

/// for objective-c type checking
extension ContentDirectory1Object {
    public func isContentDirectory1Container() -> Bool {
        return self is ContentDirectory1Container
    }
}

// MARK: - ContentDirectory1Item

@objcMembers public class ContentDirectory1Item: ContentDirectory1Object {
    public let resourceURL: URL!
    
    override init?(xmlElement: Fuzi.XMLElement) {
        /// TODO: Return nil immediately instead of waiting, see Github issue #11
        if let resourceURLString = xmlElement.firstChild(tag: "res")?.stringValue {
            resourceURL = URL(string: resourceURLString)
        } else { resourceURL = nil }
        
        super.init(xmlElement: xmlElement)
        
        guard resourceURL != nil else {
            return nil
        }
    }
}

/// for objective-c type checking
extension ContentDirectory1Object {
    public func isContentDirectory1Item() -> Bool {
        return self is ContentDirectory1Item
    }
}

// MARK: - ContentDirectory1VideoItem

@objcMembers public class ContentDirectory1VideoItem: ContentDirectory1Item {
    public let bitrate: Int?
    public let duration: TimeInterval?
    public let audioChannelCount: Int?
    public let protocolInfo: String?
    public let resolution: CGSize?
    public let sampleFrequency: Int?
    public let size: Int?
    
    override init?(xmlElement: Fuzi.XMLElement) {
        bitrate = Int(String(describing: xmlElement.firstChild(tag: "res")?.attr("bitrate")))
        
        if let durationString = xmlElement.firstChild(tag: "res")?.attr("duration") {
            let durationComponents = durationString.components(separatedBy: ":")
            var count: Double = 0
            var duration: Double = 0
            for durationComponent in durationComponents.reversed() {
                duration += (durationComponent as NSString).doubleValue * pow(60, count)
                count += 1
            }
            
            self.duration = TimeInterval(duration)
        } else { self.duration = nil }
        
        audioChannelCount = Int(String(describing: xmlElement.firstChild(tag: "res")?.attr("nrAudioChannels")))
        
        protocolInfo = xmlElement.firstChild(tag: "res")?.attr("protocolInfo")
        
        if let resolutionComponents = (xmlElement.firstChild(tag: "res")?.attr("resolution"))?.components(separatedBy: "x"),
            let width = Int(String(describing: resolutionComponents.first)),
            let height = Int(String(describing: resolutionComponents.last)) {
                resolution = CGSize(width: width, height: height)
        } else { resolution = nil }
        
        sampleFrequency = Int(String(describing: xmlElement.firstChild(tag: "res")?.attr("sampleFrequency")))
        
        size = Int(String(describing: xmlElement.firstChild(tag: "res")?.attr("size")))
        
        super.init(xmlElement: xmlElement)
    }
}

/// for objective-c type checking
extension ContentDirectory1Object {
    public func isContentDirectory1VideoItem() -> Bool {
        return self is ContentDirectory1VideoItem
    }
}

class ElementHelper {
    static func year(_ xmlElement: Fuzi.XMLElement) -> Int? {
        if let dateString = xmlElement.firstChild(tag: "date")?.stringValue {
            let dateComponents = dateString.components(separatedBy: "-")
            if dateComponents.count > 0 {
                return Int(dateComponents[0])
            }
        }
        return nil
    }

    static func artist(_ xmlElement: Fuzi.XMLElement, role: String? = nil) -> String? {
        for artistElement in xmlElement.children(tag: "artist") {
            if artistElement.attr("role") == role {
                return artistElement.stringValue
            }
        }
        return nil
    }
}

@objcMembers public class ContentDirectory1AudioItem: ContentDirectory1Item {
    public let duration: TimeInterval?
    public let bitrate: String?
    public let bitsPerSample: String?
    public let sampleFrequency: String?
    public let nrAudioChannels: String?
    public let format: String?
    public let protocolInfo: String?
    public let album: String?
    public let artist: String?
    public let albumArtist: String?
    public let composer: String?
    public let performer: String?
    public let genre: String?
    public let year: Int?
    public let discNumber: Int?
    public let trackNumber: Int?
    
    override init?(xmlElement: Fuzi.XMLElement) {
        let resChild = xmlElement.firstChild(tag: "res")
        if let durationString = resChild?.attr("duration") {
            let durationComponents = durationString.components(separatedBy: ":")
            var count: Double = 0
            var duration: Double = 0
            for durationComponent in durationComponents.reversed() {
                duration += (durationComponent as NSString).doubleValue * pow(60, count)
                count += 1
            }

            self.duration = TimeInterval(duration)
        } else { self.duration = nil }
        
        protocolInfo = resChild?.attr("protocolInfo")
        bitrate = resChild?.attr("bitrate")
        bitsPerSample = resChild?.attr("bitsPerSample")
        sampleFrequency = resChild?.attr("sampleFrequency")
        nrAudioChannels = resChild?.attr("nrAudioChannels")
        if let components = protocolInfo?.split(separator: ":"),
            let dlnaComponents = components.last?.split(separator: ";"),
            let dlnaOrgPn = dlnaComponents.first?.split(separator: "="),
            dlnaOrgPn.count > 1 {
                format = String(dlnaOrgPn[1])
        }
        else {
            format = nil
        }
        album = xmlElement.firstChild(tag: "album")?.stringValue

        genre = xmlElement.firstChild(tag: "genre")?.stringValue
        artist = ElementHelper.artist(xmlElement)
        albumArtist = ElementHelper.artist(xmlElement, role: "AlbumArtist")
        composer = ElementHelper.artist(xmlElement, role: "Composer")
        performer = ElementHelper.artist(xmlElement, role: "Performer")
        year = ElementHelper.year(xmlElement)
        discNumber = xmlElement.firstChild(tag: "originalDiscNumber")?.numberValue?.intValue
        let tn = xmlElement.firstChild(tag: "originalTrackNumber")?.numberValue?.intValue
        if let discNumber = discNumber, var convertedTn = tn, discNumber > 1 {
            while convertedTn > 100 {
                convertedTn = convertedTn - 100
            }
            trackNumber = convertedTn
        }
        else {
            trackNumber = tn
        }
        super.init(xmlElement: xmlElement)
    }
}

@objcMembers public class ContentDirectory1AlbumContainer: ContentDirectory1Container {
    public let artist: String?
    public let composer: String?
    public let performer: String?
    public let genre: String?
    public let year: Int?
    
    override init?(xmlElement: Fuzi.XMLElement) {
        genre = xmlElement.firstChild(tag: "genre")?.stringValue
        artist = ElementHelper.artist(xmlElement)
        composer = ElementHelper.artist(xmlElement, role: "Composer")
        performer = ElementHelper.artist(xmlElement, role: "Performer")
        year = ElementHelper.year(xmlElement)
        
        super.init(xmlElement: xmlElement)
    }
}

@objcMembers public class ContentDirectory1ArtistContainer: ContentDirectory1Container {
    override init?(xmlElement: Fuzi.XMLElement) {
        super.init(xmlElement: xmlElement)
    }
}

@objcMembers public class ContentDirectory1GenreContainer: ContentDirectory1Container {
    override init?(xmlElement: Fuzi.XMLElement) {
        super.init(xmlElement: xmlElement)
    }
}

extension ContentDirectory1Object {
    public func isContentDirectory1AudioItem() -> Bool {
        return self is ContentDirectory1AudioItem
    }

    public func isContentDirectory1AlbumContainer() -> Bool {
        return self is ContentDirectory1AlbumContainer
    }

    public func isContentDirectory1GenreContainer() -> Bool {
        return self is ContentDirectory1GenreContainer
    }

    public func isContentDirectory1ArtistContainer() -> Bool {
        return self is ContentDirectory1ArtistContainer
    }
}

