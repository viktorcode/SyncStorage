// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SyncStorage",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "SyncStorage",
            targets: ["SyncStorage"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SyncStorage",
            dependencies: [])
    ]
)
