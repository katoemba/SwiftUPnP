# SwiftUPnP
A Swift based UPnP implementation that draws inspiration from UPnAtom.

Key features that make this easy to use in a modern swift environment:
- Concurrency and thread safety through async/await and @MainActor
- Uses Combine for stream-based state updates.
- Strongly typed services, based on Codable structs.
- Structured logging through the os.log framework.

## System requirements
The minimum requirements for the SwiftUPnP library are:
- iOS 14
- macOS 11 Big Sur

The minimum requirement for the UPnPCodeGenerator executable is macOS 13 Ventura.

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
