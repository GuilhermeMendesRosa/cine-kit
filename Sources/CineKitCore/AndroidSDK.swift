import Foundation

public struct AndroidSDK: Sendable {
    // Apps opened from the Finder do not inherit ANDROID_HOME, so the path the app installs to is fixed (ADR 0018).
    public static let `default`: AndroidSDK = {
        let dataDirectory = URL.applicationSupportDirectory.appending(path: "CineKit/android")
        return AndroidSDK(root: dataDirectory.appending(path: "sdk"), dataDirectory: dataDirectory)
    }()

    public let root: URL
    public let dataDirectory: URL
    /// Where the emulator looks for AVDs without ANDROID_AVD_HOME.
    public let avdHome: URL
    public let avdName = "cinekit-tv"

    public init(root: URL, dataDirectory: URL, avdHome: URL = .homeDirectory.appending(path: ".android/avd")) {
        self.root = root
        self.dataDirectory = dataDirectory
        self.avdHome = avdHome
    }

    public var adb: URL { root.appending(path: "platform-tools/adb") }
    public var emulator: URL { root.appending(path: "emulator/emulator") }
    public var aapt2: URL { root.appending(path: "build-tools/35.0.0/aapt2") }
    public var scrcpyServer: URL { dataDirectory.appending(path: "scrcpy-server") }
    public var avd: URL { avdHome.appending(path: "\(avdName).avd") }

    public var isAvailable: Bool {
        [adb, emulator, aapt2, scrcpyServer, avd].allSatisfy {
            FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
        }
    }
}
