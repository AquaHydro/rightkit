// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RightKitCore",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "RightKitCore", targets: ["RightKitCore"]),
    ],
    targets: [
        .target(name: "RightKitCore", resources: [.process("Resources")]),
        .testTarget(name: "RightKitCoreTests", dependencies: ["RightKitCore"]),
    ]
)
