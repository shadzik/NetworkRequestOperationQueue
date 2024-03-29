// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkRequestOperationQueue",
    platforms: [
        .macOS(.v10_14), .iOS(.v15), .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetworkRequestOperationQueue",
            targets: ["NetworkRequestOperationQueue"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NetworkRequestOperationQueue"),
        .testTarget(
            name: "NetworkRequestOperationQueueTests",
            dependencies: ["NetworkRequestOperationQueue",
                           .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
                          ]),
    ]
)
