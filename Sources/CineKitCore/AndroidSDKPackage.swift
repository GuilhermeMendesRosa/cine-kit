import Foundation

/// A pinned download of the Android SDK (ADR 0018); `dl.google.com` publishes sha1, scrcpy publishes sha256.
public struct AndroidSDKPackage: Sendable, Equatable {
    public enum Checksum: Sendable, Equatable {
        case sha1(String)
        case sha256(String)
    }

    public enum Destination: Sendable, Equatable {
        /// The zip's single top-level folder is moved to this path inside the SDK root.
        case sdk(String)
        case scrcpyServer
    }

    public let name: String
    public let url: URL
    public let checksum: Checksum
    public let size: Int64
    public let destination: Destination

    public init(name: String, url: URL, checksum: Checksum, size: Int64, destination: Destination) {
        self.name = name
        self.url = url
        self.checksum = checksum
        self.size = size
        self.destination = destination
    }

    // Versions, URLs and sha1 come from repository2-3.xml and sys-img/android-tv/sys-img2-3.xml.
    private static let repository = "https://dl.google.com/android/repository"

    public static let pinned: [AndroidSDKPackage] = [
        AndroidSDKPackage(
            name: "Platform tools",
            url: URL(string: "\(repository)/platform-tools_r37.0.1-darwin.zip")!,
            checksum: .sha1("6ae73f4de6452dc57e62ec02b68eed92a4c21661"),
            size: 16_110_554,
            destination: .sdk("platform-tools")
        ),
        AndroidSDKPackage(
            name: "Build tools",
            url: URL(string: "\(repository)/build-tools_r35_macosx.zip")!,
            checksum: .sha1("93ab8ce91230e067b5add4bfa79919c52b27f072"),
            size: 76_857_898,
            destination: .sdk("build-tools/35.0.0")
        ),
        AndroidSDKPackage(
            name: "Emulador",
            url: URL(string: "\(repository)/emulator-darwin_aarch64-16428233.zip")!,
            checksum: .sha1("3af4fe44ce82b3d88ae5678a53735f27ad729c15"),
            size: 416_112_708,
            destination: .sdk("emulator")
        ),
        AndroidSDKPackage(
            name: "Android TV",
            url: URL(string: "\(repository)/sys-img/android-tv/arm64-v8a-36_r04.zip")!,
            checksum: .sha1("ceb1dfcc6a28dbd9dbade780428cf7bafb1c65ef"),
            size: 970_375_839,
            destination: .sdk(AndroidAVD.systemImage)
        ),
        // The scrcpy protocol changes between versions: updating it means reviewing ScrcpyControlMessage (ADR 0004).
        AndroidSDKPackage(
            name: "scrcpy-server",
            url: URL(string: "https://github.com/Genymobile/scrcpy/releases/download/v5.0.1/scrcpy-server-v5.0.1")!,
            checksum: .sha256("764eb6f79811d5211fe9df341120882ba9994c7a61b897d7bf3fb662e53bc536"),
            size: 733_930,
            destination: .scrcpyServer
        ),
    ]
}
