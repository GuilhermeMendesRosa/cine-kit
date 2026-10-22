import Foundation

public struct AndroidSDK: Sendable {
    // Apps opened from the Finder do not inherit ANDROID_HOME, so the path set by scripts/android-setup.sh is fixed.
    public static let `default` = AndroidSDK(
        root: URL(filePath: "/opt/homebrew/share/android-commandlinetools"),
        dataDirectory: .applicationSupportDirectory.appending(path: "CineKit/android")
    )

    public let root: URL
    public let dataDirectory: URL
    public let avdName = "cinekit-tv"

    public init(root: URL, dataDirectory: URL) {
        self.root = root
        self.dataDirectory = dataDirectory
    }

    public var adb: URL { root.appending(path: "platform-tools/adb") }
    public var emulator: URL { root.appending(path: "emulator/emulator") }
    public var aapt2: URL { root.appending(path: "build-tools/35.0.0/aapt2") }
    public var scrcpyServer: URL { dataDirectory.appending(path: "scrcpy-server") }

    public var isAvailable: Bool {
        let avd = URL.homeDirectory.appending(path: ".android/avd/\(avdName).avd")
        return [adb, emulator, aapt2, scrcpyServer, avd].allSatisfy {
            FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
        }
    }
}
