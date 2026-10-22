import CineKitCore
import Foundation
import Network

/// Injects keys and text through scrcpy-server v5.0.1 (ADR 0004); the video comes from the emulator (ADR 0009).
/// Wire format: scrcpy `doc/develop.md` ("Protocol") at the pinned version.
@MainActor
final class ScrcpyClient {
    private static let version = "5.0.1"
    private static let remotePath = "/data/local/tmp/scrcpy-server.jar"

    enum ClientError: Error {
        case closed
        case serverUnreachable
    }

    private let sdk: AndroidSDK
    private let runner: CommandRunner
    private var server: RunningProcess?
    private var port: UInt16?
    private var control: NWConnection?

    init(sdk: AndroidSDK, runner: CommandRunner) {
        self.sdk = sdk
        self.runner = runner
    }

    func start() async throws {
        let scid = String(format: "%08x", Int32.random(in: 1...Int32.max))
        let port = UInt16.random(in: 27183...27283)
        self.port = port
        _ = try await adb("push", sdk.scrcpyServer.path(percentEncoded: false), Self.remotePath)
        _ = try await adb("forward", "tcp:\(port)", "localabstract:scrcpy_\(scid)")
        server = try runner.launch(sdk.adb, [
            "-s", AndroidRuntime.serial, "shell", "CLASSPATH=\(Self.remotePath)", "app_process", "/",
            "com.genymobile.scrcpy.Server", Self.version, "scid=\(scid)", "tunnel_forward=true",
            "video=false", "audio=false", "control=true", "cleanup=true",
        ])

        // With a forward tunnel, adb accepts the connection even before the server listens;
        // the dummy byte confirms the server is on the other side.
        for _ in 0..<50 {
            let connection = Self.connect(port)
            if (try? await Self.receive(connection, 1)) != nil {
                control = connection
                break
            }
            connection.cancel()
            try await Task.sleep(for: .milliseconds(100))
        }
        guard let control else { throw ClientError.serverUnreachable }
        _ = try await Self.receive(control, 64) // device name
    }

    func send(_ message: ScrcpyControlMessage) {
        control?.send(content: message.encoded, completion: .idempotent)
    }

    func stop() {
        control?.cancel()
        server?.terminate()
        if let port {
            _ = try? runner.launch(sdk.adb, ["-s", AndroidRuntime.serial, "forward", "--remove", "tcp:\(port)"])
        }
        server = nil
        port = nil
    }

    private func adb(_ arguments: String...) async throws -> String {
        try await runner.run(sdk.adb, ["-s", AndroidRuntime.serial] + arguments)
    }

    private static func connect(_ port: UInt16) -> NWConnection {
        let tcp = NWProtocolTCP.Options()
        tcp.noDelay = true
        let connection = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!, using: NWParameters(tls: nil, tcp: tcp))
        connection.start(queue: .main)
        return connection
    }

    private static func receive(_ connection: NWConnection, _ count: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: count, maximumLength: count) { data, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, data.count == count {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ClientError.closed)
                }
            }
        }
    }
}
