// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CineKit",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "CineKitCore"),
        .executableTarget(name: "CineKit", dependencies: ["CineKitCore"], resources: [.process("Resources")]),
        .testTarget(name: "CineKitCoreTests", dependencies: ["CineKitCore"]),
    ]
)
