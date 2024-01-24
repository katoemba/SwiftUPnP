// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUPnP",
    platforms: [.iOS(.v14), .macOS(.v11), .watchOS(.v10)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftUPnP",
            targets: ["SwiftUPnP"]),
        .executable(
            name: "UPnPCodeGenerator",
            targets: ["UPnPCodeGenerator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.13.1"),
        .package(url: "https://github.com/httpswift/swifter", branch: "stable"),
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", branch: "master"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftUPnP",
            dependencies: [.product(name: "XMLCoder", package: "xmlcoder"),
                           .product(name: "Swifter", package: "swifter"),
                           .product(name: "CocoaAsyncSocket", package: "cocoaasyncsocket")],
            path: "Source"),
        .executableTarget(
            name: "UPnPCodeGenerator",
            dependencies: [.product(name: "XMLCoder", package: "xmlcoder")],
            path: "CodeGenerator"),
        .testTarget(
            name: "SwiftUPnPTests",
            dependencies: ["SwiftUPnP", 
                           .product(name: "Mocker", package: "mocker")],
            resources: [.process("Resources")])
        ]
)
