// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Dynamic",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Dynamic", targets: ["Dynamic"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Dynamic", dependencies: []),
        .testTarget(name: "DynamicTests", dependencies: ["Dynamic"])
    ]
)
