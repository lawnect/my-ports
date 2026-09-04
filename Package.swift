// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShowMeThePorts",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ShowMeThePorts", targets: ["ShowMeThePorts"]),
        .library(name: "ShowMeThePortsCore", targets: ["ShowMeThePortsCore"])
    ],
    targets: [
        .target(name: "ShowMeThePortsCore"),
        .executableTarget(
            name: "ShowMeThePorts",
            dependencies: ["ShowMeThePortsCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ShowMeThePortsCoreTests",
            dependencies: ["ShowMeThePortsCore"]
        )
    ]
)
