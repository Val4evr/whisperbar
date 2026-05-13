// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WhisperBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhisperBar", targets: ["WhisperBar"]),
        .library(name: "WhisperBarCore", targets: ["WhisperBarCore"])
    ],
    targets: [
        .target(
            name: "WhisperBarCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "WhisperBar",
            dependencies: ["WhisperBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "WhisperBarCoreTests",
            dependencies: ["WhisperBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
