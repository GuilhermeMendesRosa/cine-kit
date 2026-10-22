// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CineKit",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "CineKitCore"),
        .executableTarget(name: "CineKit", dependencies: ["CineKitCore"]),
        .testTarget(name: "CineKitCoreTests", dependencies: ["CineKitCore"]),
    ]
)
