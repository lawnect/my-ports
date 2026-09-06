// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PortPig",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PortPig", targets: ["PortPig"]),
        .library(name: "PortPigCore", targets: ["PortPigCore"])
    ],
    targets: [
        .target(name: "PortPigCore"),
        .executableTarget(
            name: "PortPig",
            dependencies: ["PortPigCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PortPigCoreTests",
            dependencies: ["PortPigCore"]
        )
    ]
)
