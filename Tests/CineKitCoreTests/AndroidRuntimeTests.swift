import Foundation
import Testing
@testable import CineKitCore

private final class FakeProcess: RunningProcess {
    var isRunning = true
    func terminate() { isRunning = false }
}

/// Records every command and answers from `outputs`, keyed by the arguments joined with spaces.
/// A key with several outputs returns them in order and then repeats the last one.
private final class FakeRunner: CommandRunner, @unchecked Sendable {
    var outputs: [String: [Result<String, CommandError>]] = [:]
    var calls: [String] = []
    var launched: [String] = []

    func respond(_ arguments: String, _ results: String...) {
        outputs[arguments] = results.map { .success($0) }
    }

    func fail(_ arguments: String) {
        outputs[arguments] = [.failure(.failed(status: 1, output: "error"))]
    }

    func run(_ executable: URL, _ arguments: [String]) async throws -> String {
        let key = arguments.joined(separator: " ")
        calls.append("\(executable.lastPathComponent) \(key)")
        guard var results = outputs[key] else { return "" }
        let result = results.count > 1 ? results.removeFirst() : results[0]
        outputs[key] = results
        return try result.get()
    }

    func launch(_ executable: URL, _ arguments: [String]) throws -> RunningProcess {
        launched.append("\(executable.lastPathComponent) \(arguments.joined(separator: " "))")
        return FakeProcess()
    }
}

@MainActor
struct AndroidRuntimeTests {
    fileprivate let runner = FakeRunner()
    let runtime: AndroidRuntime

    init() {
        let sdk = AndroidSDK(root: URL(filePath: "/sdk"), dataDirectory: URL(filePath: "/data"))
        runtime = AndroidRuntime(sdk: sdk, runner: runner, sleep: { _ in })
    }

    private func hardware(_ resolution: AndroidRuntime.Resolution, cores: Int = 4, memoryMB: Int = 2048) -> AndroidRuntime.Hardware {
        AndroidRuntime.Hardware(resolution: resolution, cores: cores, memoryMB: memoryMB, hostCores: 10, physicalMemory: 16 << 30)
    }

    @Test func startLaunchesHeadlessEmulatorWith1080pSkin() async throws {
        runner.respond("devices", "List of devices attached\n\n")

        try await runtime.start(hardware(.hd1080))

        #expect(runner.launched == [
            "emulator -avd cinekit-tv -no-window -no-boot-anim -share-vid -feature -HardwareDecoder -skin 1920x1080 -prop qemu.sf.lcd_density=320 -cores 4 -memory 2048",
        ])
    }

    @Test func startUses4KSkinAndDensity() async throws {
        try await runtime.start(hardware(.uhd4k))

        #expect(runner.launched == [
            "emulator -avd cinekit-tv -no-window -no-boot-anim -share-vid -feature -HardwareDecoder -skin 3840x2160 -prop qemu.sf.lcd_density=640 -cores 4 -memory 2048",
        ])
    }

    @Test func startPassesTheChosenCoresAndMemory() async throws {
        try await runtime.start(hardware(.hd1080, cores: 8, memoryMB: 8192))

        #expect(runner.launched.first?.hasSuffix("-cores 8 -memory 8192") == true)
    }

    @Test func startReusesRunningEmulator() async throws {
        runner.respond("devices", "List of devices attached\nemulator-5554\tdevice\n\n")

        try await runtime.start(hardware(.hd1080))

        #expect(runner.launched.isEmpty)
    }

    @Test func waitUntilBootedPollsUntilBootCompleted() async throws {
        runner.respond("-s emulator-5554 shell getprop sys.boot_completed", "\n", "\n", "1\n")

        try await runtime.waitUntilBooted()

        #expect(runner.calls.count == 3)
    }

    @Test func waitUntilBootedThrowsAfterTimeout() async throws {
        runner.fail("-s emulator-5554 shell getprop sys.boot_completed")

        await #expect(throws: AndroidRuntimeError.bootTimeout) { try await runtime.waitUntilBooted(timeout: 5) }
        #expect(runner.calls.count == 5)
    }

    @Test func installReadsBadgingThenInstalls() async throws {
        runner.respond("dump badging /tmp/jellyfin.apk", "package: name='org.jellyfin.androidtv' versionCode='1'\napplication-label:'Jellyfin'\n")

        let installed = try await runtime.install(apk: URL(filePath: "/tmp/jellyfin.apk"))

        #expect(installed.package == "org.jellyfin.androidtv")
        #expect(installed.label == "Jellyfin")
        #expect(runner.calls == [
            "aapt2 dump badging /tmp/jellyfin.apk",
            "adb -s emulator-5554 shell settings put global verifier_verify_adb_installs 0",
            "adb -s emulator-5554 install -r /tmp/jellyfin.apk",
        ])
    }

    @Test func launchFallsBackToLauncherCategory() async throws {
        let resolve = "-s emulator-5554 shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c"
        runner.respond("\(resolve) android.intent.category.LEANBACK_LAUNCHER org.example.phone", "No activity found\n")
        runner.respond(
            "\(resolve) android.intent.category.LAUNCHER org.example.phone",
            "priority=0 preferredOrder=0 match=0x108000 specificIndex=-1 isDefault=true\norg.example.phone/.MainActivity\n"
        )

        try await runtime.launch(package: "org.example.phone")

        #expect(runner.calls.last == "adb -s emulator-5554 shell am start -n org.example.phone/.MainActivity")
    }

    @Test func launchMaxesMediaVolumeSoTheMacControlsIt() async throws {
        runner.respond(
            "-s emulator-5554 shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LEANBACK_LAUNCHER org.jellyfin.androidtv",
            "org.jellyfin.androidtv/.MainActivity\n"
        )

        try await runtime.launch(package: "org.jellyfin.androidtv")

        #expect(runner.calls.contains("adb -s emulator-5554 shell cmd audio set-volume 3 15"))
    }

    @Test func ensureRunningRestartsDeadEmulatorOnce() async throws {
        runner.respond("devices", "List of devices attached\n\n")

        try await runtime.ensureRunning(hardware(.hd1080))

        #expect(runner.launched.count == 1)
    }

    @Test func uninstallCallsAdb() async throws {
        try await runtime.uninstall(package: "org.jellyfin.androidtv")

        #expect(runner.calls == ["adb -s emulator-5554 uninstall org.jellyfin.androidtv"])
    }

    @Test func pauseMediaSendsMediaPauseKey() async throws {
        try await runtime.pauseMedia()

        #expect(runner.calls == ["adb -s emulator-5554 shell input keyevent 127"])
    }

    @Test func restartStopsThenStartsWithNewHardware() async throws {
        runner.respond("devices", "List of devices attached\nemulator-5554\tdevice\n\n", "List of devices attached\n\n")

        try await runtime.restart(hardware(.uhd4k, cores: 6, memoryMB: 4096))

        #expect(runner.launched == [
            "adb -s emulator-5554 emu kill",
            "emulator -avd cinekit-tv -no-window -no-boot-anim -share-vid -feature -HardwareDecoder -skin 3840x2160 -prop qemu.sf.lcd_density=640 -cores 6 -memory 4096",
        ])
    }

    @Test func startWithIdentityAddsTheRamdiskAndSerial() async throws {
        var identity = AndroidIdentity.profiles[0]
        identity.serial = "0123456789ABCDEF"
        runtime.identity = identity

        try await runtime.start(hardware(.hd1080))

        #expect(runner.launched.first?.hasSuffix("-ramdisk /data/identity-ramdisk.img -android-serialno 0123456789ABCDEF") == true)
    }

    @Test func applyBacksUpApksWipesWithTheNewRamdiskAndReinstalls() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let sdk = AndroidSDK(root: directory.appending(path: "sdk"), dataDirectory: directory)
        try FileManager.default.createDirectory(at: sdk.systemImage, withIntermediateDirectories: true)
        try Data([1, 2, 3, 4]).write(to: sdk.systemImage.appending(path: "ramdisk.img"))
        let runtime = AndroidRuntime(sdk: sdk, runner: runner, sleep: { _ in })
        runner.respond("devices", "List of devices attached\nemulator-5554\tdevice\n\n", "List of devices attached\nemulator-5554\tdevice\n\n", "List of devices attached\n\n")
        runner.respond("-s emulator-5554 shell getprop sys.boot_completed", "1\n")
        runner.respond("-s emulator-5554 shell pm list packages -3", "package:org.jellyfin.androidtv\n")
        runner.respond("-s emulator-5554 shell pm path org.jellyfin.androidtv", "package:/data/app/x/base.apk\npackage:/data/app/x/split_config.arm64_v8a.apk\n")
        var identity = AndroidIdentity.profiles[1]
        identity.serial = "0123456789ABCDEF"

        try await runtime.apply(identity, hardware(.hd1080))

        let backup = directory.appending(path: "identity-apks/org.jellyfin.androidtv").path(percentEncoded: false)
        #expect(runner.calls.contains("adb -s emulator-5554 pull /data/app/x/base.apk \(backup)/base.apk"))
        #expect(runner.calls.last == "adb -s emulator-5554 install-multiple -r \(backup)/base.apk \(backup)/split_config.arm64_v8a.apk")
        #expect(runner.launched.last?.hasSuffix("-android-serialno 0123456789ABCDEF -wipe-data -no-snapshot-load") == true)
        #expect(runtime.identity == identity)
        let ramdisk = try Data(contentsOf: sdk.identityRamdisk)
        #expect(ramdisk.prefix(4) == Data([1, 2, 3, 4]))
        #expect(!FileManager.default.fileExists(atPath: directory.appending(path: "identity-apks").path(percentEncoded: false)))
    }
}
