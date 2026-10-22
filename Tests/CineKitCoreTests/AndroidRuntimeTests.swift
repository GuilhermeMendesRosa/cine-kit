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

    @Test func startLaunchesHeadlessEmulatorWith1080pSkin() async throws {
        runner.respond("devices", "List of devices attached\n\n")

        try await runtime.start(resolution: .hd1080)

        #expect(runner.launched == [
            "emulator -avd cinekit-tv -no-window -no-boot-anim -skin 1920x1080 -prop qemu.sf.lcd_density=320",
        ])
    }

    @Test func startUses4KSkinAndDensity() async throws {
        try await runtime.start(resolution: .uhd4k)

        #expect(runner.launched == [
            "emulator -avd cinekit-tv -no-window -no-boot-anim -skin 3840x2160 -prop qemu.sf.lcd_density=640",
        ])
    }

    @Test func startReusesRunningEmulator() async throws {
        runner.respond("devices", "List of devices attached\nemulator-5554\tdevice\n\n")

        try await runtime.start(resolution: .hd1080)

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
}
