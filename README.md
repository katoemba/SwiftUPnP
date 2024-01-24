[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkatoemba%2FSwiftUPnP%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/katoemba/SwiftUPnP)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkatoemba%2FSwiftUPnP%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/katoemba/SwiftUPnP)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-green)](https://img.shields.io/badge/Swift_Package_Manager-compatible-green)

# SwiftUPnP
SwiftUPnP is a Swift-based library that provides a comprehensive set of APIs for developers to implement the UPnP (Universal Plug and Play) and OpenHome protocols. With SwiftUPnP, developers can integrate UPnP and OpenHome support into their iOS, macOS, and tvOS apps, allowing users to discover and control audio devices on their network.

SwiftUPnP implements the full set of UPnP and OpenHome services, including event processing. This means that developers can create real-time apps that can handle UPnP and OpenHome events, such as changes in the status of a device or the addition of a new device to the network. With SwiftUPnP, developers can implement event processing by subscribing to device services and receiving notifications when events occur.

Overall, SwiftUPnP is a useful tool for developers who want to add UPnP and OpenHome support to their app. The library provides a straightforward and efficient way to create audio streaming and device control apps, allowing users to easily discover and control audio devices on their network.

Key features that make this easy to use in a modern swift environment:
- Concurrency and thread safety through async/await and @MainActor
- Uses Combine for stream-based state updates.
- Strongly typed services, based on Codable structs.
- Structured logging through the os.log framework.

## System requirements
The minimum requirements for the SwiftUPnP library are:
- iOS 14
- macOS 11 Big Sur

## Device discovery
SSDP discovery is done using CocoaAsyncSocket. There is also support for using the standard Apple Network framework, but this has a known issue when another app is also listening for UPnP devices. 
Only devices are discovered, the available sources are loaded based on the description of the device.
(Dis)appearance of devices on the network is published via Combine publishers defined in UPnPRegistery: deviceAdded and deviceRemoved. When a device is published on the subject, it's fully loaded with all included service definitions.

```swift
    private let openHomeRegistry = UPnPRegistry.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        openHomeRegistry.deviceAdded
            .sink {
                print("Detected device \($0.deviceDefinition.device.friendlyName) of type \($0.deviceType)")
            }
            .store(in: &cancellables)
        
        openHomeRegistry.deviceRemoved
            .sink {
                print("Removed device \($0.deviceDefinition.device.friendlyName) of type \($0.deviceType)")
            }
            .store(in: &cancellables)
    }

    public func startListening() {
        try? openHomeRegistry.startDiscovery()
    }
    
    public func stopListening() {
        openHomeRegistry.stopDiscovery()
    }
```

## Actions
UPnP actions and responses are strongly typed, no key-value pairs. This is done through Codable structs. All action calls are implemented as async functions.

```swift
    let device: UPnPDevice
    
    try? await device.openHomeVolume1Service?.setVolume(value: 50)
```

## State changes
Every service implementation has a Combine publisher stateSubject. When the service subscribes to state changes via subscribeToEvents(), those events will be delivered on the stateSubject as strongly typed structs.
To receive state changes, a small webserver will be run (Swifter).

```swift
    let device: UPnPDevice
    var cancellables = Set<AnyCancellable>()

    if let service = device.openHomeVolume1Service {
        service.stateSubject
            .sink {
                print("Received volume change, volume = \($0.volume ?? -1)")
            }
            .store(in: &cancellables)
            
        Task {
            await service.subscribeToEvents()
        }
    }
```


## Service generator
A command line tool to generate swift based service implementations from a xml-based <scdp> file is included. This is used to generate
the swift sources in the AV Profile and OpenHome Profile folders.
Code generation includes creation of enums for allowed values, all defined actions and state changes.

### Supported services
A full implementation of all standard UPnP services and state changes:
- ConnectionManager
- ContentDirectory
- RenderingControl
- AVTransport

A full implementation of standard OpenHome services and state changes:
- OpenHomeConfig
- OpenHomeCredentials
- OpenHomeInfo
- OpenHomeOAuth
- OpenHomePins
- OpenHomePlaylist
- OpenHomePlaylistManager
- OpenHomeProduct(1 or 2)
- OpenHomeRadio
- OpenHomeReceiver
- OpenHomeSender
- OpenHomeTime
- OpenHomeTransport
- OpenHomeVolume(1 or 2)

## How to include in a project
The package can be included using Swift Package Manager.

## License
SwiftUPnP is released under the MIT license.

## Dependencies
SwiftUPnP use the following packages:
- Swifter provides a small http server to listen for state changes triggered by UPnP devices.
- XMLCoder is used to encode and decode SOAP envelopes.
- CocoaAsyncSocket to detect UPnP devices on the network using multicast.
