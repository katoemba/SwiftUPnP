// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUPnP",
    // Change the macOS version to .v13 to compile UPnPCodeGenerator
    platforms: [.iOS(.v14), .macOS(.v11)],
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
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftUPnP",
            dependencies: ["XMLCoder", .product(name: "Swifter", package: "swifter"), "CocoaAsyncSocket"],
            path: "Source"),
        .executableTarget(
            name: "UPnPCodeGenerator",
            dependencies: ["XMLCoder"],
            path: "CodeGenerator"),
    ]
)
