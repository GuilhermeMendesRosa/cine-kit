import Foundation

public protocol RunningProcess: AnyObject {
    var isRunning: Bool { get }
    func terminate()
}

extension Process: RunningProcess {}

public protocol CommandRunner: Sendable {
    /// Runs to completion and returns stdout; throws `CommandError.failed` on a non-zero status.
    func run(_ executable: URL, _ arguments: [String]) async throws -> String
    /// Starts without waiting; the output is discarded.
    func launch(_ executable: URL, _ arguments: [String]) throws -> RunningProcess
}

public enum CommandError: Error, Equatable {
    case failed(status: Int32, output: String)
}

public struct ProcessCommandRunner: CommandRunner {
    public init() {}

    public func run(_ executable: URL, _ arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            // Reading blocks until the process closes stdout, so it runs off the caller's thread.
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = executable
                process.arguments = arguments
                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                let output = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                let errors = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: CommandError.failed(status: process.terminationStatus, output: output + errors))
                }
            }
        }
    }

    public func launch(_ executable: URL, _ arguments: [String]) throws -> RunningProcess {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        return process
    }
}
