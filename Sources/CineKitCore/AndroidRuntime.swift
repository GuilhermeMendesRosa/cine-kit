import Foundation
import Observation
import os

public enum AndroidRuntimeError: Error, Equatable {
    case bootTimeout
    case invalidApk
    case noLaunchableActivity
}

/// Drives the hidden Android TV emulator through `adb` (ADR 0004).
@MainActor
@Observable
public final class AndroidRuntime {
    public enum Resolution: String, Sendable {
        case hd1080, uhd4k

        var skin: String {
            switch self {
            case .hd1080: "1920x1080"
            case .uhd4k: "3840x2160"
            }
        }

        var density: Int {
            switch self {
            case .hd1080: 320
            case .uhd4k: 640
            }
        }
    }

    public static let serial = "emulator-5554"
    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "AndroidRuntime")

    private let sdk: AndroidSDK
    private let runner: CommandRunner
    private let sleep: (Duration) async throws -> Void
    private var emulator: RunningProcess?
    /// When set, every boot reads as this device: `-ramdisk` carries its props (`AndroidIdentity`).
    public var identity: AndroidIdentity?

    public init(sdk: AndroidSDK, runner: CommandRunner, sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.sdk = sdk
        self.runner = runner
        self.sleep = sleep
    }

    public func start(resolution: Resolution) async throws {
        if try await deviceState() == "device" { return }
        emulator = try runner.launch(sdk.emulator, arguments(resolution: resolution))
    }

    private func arguments(resolution: Resolution) -> [String] {
        // The goldfish hardware decoders never return frames in a headless emulator; the software ones do.
        var arguments = [
            "-avd", sdk.avdName, "-no-window", "-no-boot-anim", "-share-vid", "-feature", "-HardwareDecoder",
            "-skin", resolution.skin, "-prop", "qemu.sf.lcd_density=\(resolution.density)",
        ]
        if let identity {
            arguments += ["-ramdisk", sdk.identityRamdisk.path(percentEncoded: false), "-android-serialno", identity.serial]
        }
        return arguments
    }

    /// Polls once per second; an offline emulator makes `adb shell` fail, which counts as not booted yet.
    public func waitUntilBooted(timeout: Int = 90) async throws {
        for _ in 0..<timeout {
            let booted = try? await adb("shell", "getprop", "sys.boot_completed")
            if booted?.trimmingCharacters(in: .whitespacesAndNewlines) == "1" { return }
            try await sleep(.seconds(1))
        }
        throw AndroidRuntimeError.bootTimeout
    }

    /// Changing the resolution needs a cold start: `-skin` only applies at launch.
    public func restart(resolution: Resolution) async throws {
        try await stopAndWait()
        try await start(resolution: resolution)
    }

    /// Without root, a new ANDROID_ID takes wiping the data, so the third-party APKs are pulled first and installed back.
    /// The first boot is cold, since a snapshot would bring back the old props; later ones save and load snapshots as usual.
    public func apply(_ identity: AndroidIdentity, resolution: Resolution) async throws {
        try await ensureRunning(resolution: resolution)
        try await waitUntilBooted()
        let backup = sdk.dataDirectory.appending(path: "identity-apks")
        try? FileManager.default.removeItem(at: backup)
        defer { try? FileManager.default.removeItem(at: backup) }
        var apps: [[String]] = []
        for line in try await adb("shell", "pm", "list", "packages", "-3").split(separator: "\n") {
            let package = line.trimmingCharacters(in: .whitespaces).replacing("package:", with: "")
            guard !package.isEmpty else { continue }
            let directory = backup.appending(path: package)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var apks: [String] = []
            // Split APKs come as several lines: base.apk, split_config.*.apk.
            for path in try await adb("shell", "pm", "path", package).split(separator: "\n") {
                let remote = path.trimmingCharacters(in: .whitespaces).replacing("package:", with: "")
                guard !remote.isEmpty else { continue }
                let local = directory.appending(path: URL(filePath: remote).lastPathComponent).path(percentEncoded: false)
                _ = try await adb("pull", remote, local)
                apks.append(local)
            }
            apps.append(apks)
        }
        let stock = try Data(contentsOf: sdk.systemImage.appending(path: "ramdisk.img"))
        try identity.ramdisk(appendingTo: stock).write(to: sdk.identityRamdisk)
        self.identity = identity
        try await stopAndWait()
        emulator = try runner.launch(sdk.emulator, arguments(resolution: resolution) + ["-wipe-data", "-no-snapshot-load"])
        try await waitUntilBooted(timeout: 300)
        _ = try await adb("shell", "settings", "put", "global", "verifier_verify_adb_installs", "0")
        for apks in apps where !apks.isEmpty {
            _ = try await adb(["install-multiple", "-r"] + apks)
        }
    }

    private func stopAndWait() async throws {
        stop()
        for _ in 0..<30 {
            guard try await deviceState() != nil else { break }
            try await sleep(.seconds(1))
        }
    }

    /// Starts the emulator again when `adb devices` no longer lists it.
    public func ensureRunning(resolution: Resolution) async throws {
        guard try await deviceState() == nil else { return }
        try await start(resolution: resolution)
    }

    public func install(apk: URL) async throws -> (package: String, label: String) {
        let path = apk.path(percentEncoded: false)
        guard let badging = ApkBadging.parse(try await runner.run(sdk.aapt2, ["dump", "badging", path])) else {
            throw AndroidRuntimeError.invalidApk
        }
        // The TV image ships Play Protect, whose "Install anyway" dialog would wait on the hidden screen.
        _ = try await adb("shell", "settings", "put", "global", "verifier_verify_adb_installs", "0")
        _ = try await adb("install", "-r", path)
        return badging
    }

    public func uninstall(package: String) async throws {
        _ = try await adb("uninstall", package)
    }

    /// TV apps declare LEANBACK_LAUNCHER; phone apps only LAUNCHER.
    public func launch(package: String) async throws {
        // Media volume (stream 3) at its maximum, 15, so the Mac's volume is the one that matters.
        _ = try await adb("shell", "cmd", "audio", "set-volume", "3", "15")
        for category in ["android.intent.category.LEANBACK_LAUNCHER", "android.intent.category.LAUNCHER"] {
            let output = try await adb("shell", "cmd", "package", "resolve-activity", "--brief", "-a", "android.intent.action.MAIN", "-c", category, package)
            // The component is the last line; "No activity found" when the category is missing.
            if let component = output.split(separator: "\n").last, component.contains("/") {
                _ = try await adb("shell", "am", "start", "-n", String(component))
                return
            }
        }
        throw AndroidRuntimeError.noLaunchableActivity
    }

    public func foregroundPackage() async throws -> String? {
        ForegroundActivity.package(fromDumpsys: try await adb("shell", "dumpsys", "activity", "activities"))
    }

    public func pauseMedia() async throws {
        _ = try await adb("shell", "input", "keyevent", "127")
    }

    public func pressHome() async throws {
        _ = try await adb("shell", "input", "keyevent", "3")
    }

    /// Synchronous so it can run in `applicationWillTerminate`; `emu kill` also stops an emulator this app did not launch.
    public func stop() {
        do {
            _ = try runner.launch(sdk.adb, ["-s", Self.serial, "emu", "kill"])
        } catch {
            Self.logger.error("adb emu kill failed: \(error)")
        }
        emulator?.terminate()
        emulator = nil
    }

    private func adb(_ arguments: String...) async throws -> String {
        try await adb(arguments)
    }

    private func adb(_ arguments: [String]) async throws -> String {
        try await runner.run(sdk.adb, ["-s", Self.serial] + arguments)
    }

    /// The emulator's state in `adb devices` (`device`, `offline`…), or nil when it is not listed.
    private func deviceState() async throws -> String? {
        let output = try await runner.run(sdk.adb, ["devices"])
        for line in output.split(separator: "\n") {
            let fields = line.split(whereSeparator: \.isWhitespace)
            if fields.count == 2, fields[0] == Self.serial { return String(fields[1]) }
        }
        return nil
    }
}
