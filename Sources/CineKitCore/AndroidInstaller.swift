import CryptoKit
import Foundation
import Observation

public protocol Downloader: Sendable {
    /// Downloads to a temporary file the caller then owns; `progress` gets the bytes received so far.
    func download(_ url: URL, progress: @escaping @Sendable (Int64) -> Void) async throws -> URL
}

public enum AndroidInstallerError: Error, Equatable {
    case checksumMismatch(String)
    case unexpectedArchive(String)
}

/// Downloads the pinned Android SDK and writes the AVD, without sdkmanager or Java (ADR 0018).
/// Each package is moved into place only once complete, so an interrupted install resumes at the missing ones.
@MainActor
@Observable
public final class AndroidInstaller {
    public enum State: Equatable {
        case idle
        case installing(step: String, fraction: Double)
    }

    public private(set) var state = State.idle

    private let sdk: AndroidSDK
    private let packages: [AndroidSDKPackage]
    private let downloader: Downloader
    private let runner: CommandRunner
    private let fileManager = FileManager.default

    public init(sdk: AndroidSDK, packages: [AndroidSDKPackage] = AndroidSDKPackage.pinned, downloader: Downloader, runner: CommandRunner) {
        self.sdk = sdk
        self.packages = packages
        self.downloader = downloader
        self.runner = runner
    }

    public func install() async throws {
        defer { state = .idle }
        let missing = packages.filter { !exists(destination(of: $0)) }
        let total = Double(max(missing.map(\.size).reduce(0, +), 1))
        var done: Int64 = 0
        for package in missing {
            state = .installing(step: package.name, fraction: Double(done) / total)
            let offset = done
            let file = try await downloader.download(package.url) { received in
                Task { @MainActor in
                    guard case .installing(let step, _) = self.state, step == package.name else { return }
                    self.state = .installing(step: step, fraction: min(Double(offset + received) / total, 1))
                }
            }
            defer { try? fileManager.removeItem(at: file) }
            try await verify(file, package)
            try await place(file, package)
            done += package.size
        }
        state = .installing(step: "Android TV", fraction: 1)
        try writeAVD()
    }

    private func destination(of package: AndroidSDKPackage) -> URL {
        switch package.destination {
        case .sdk(let path): sdk.root.appending(path: path)
        case .scrcpyServer: sdk.scrcpyServer
        }
    }

    private func exists(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path(percentEncoded: false))
    }

    private func verify(_ file: URL, _ package: AndroidSDKPackage) async throws {
        // Hashing a 1 GB system image would stall the main actor.
        let matches = try await Task.detached { try Self.digest(of: file, package.checksum) }.value
        guard matches else { throw AndroidInstallerError.checksumMismatch(package.name) }
    }

    private nonisolated static func digest(of file: URL, _ checksum: AndroidSDKPackage.Checksum) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var sha1 = Insecure.SHA1()
        var sha256 = SHA256()
        while let chunk = try handle.read(upToCount: 4 << 20), !chunk.isEmpty {
            switch checksum {
            case .sha1: sha1.update(data: chunk)
            case .sha256: sha256.update(data: chunk)
            }
        }
        let hex: (any Digest) -> String = { $0.map { String(format: "%02x", $0) }.joined() }
        switch checksum {
        case .sha1(let expected): return hex(sha1.finalize()) == expected
        case .sha256(let expected): return hex(sha256.finalize()) == expected
        }
    }

    private func place(_ file: URL, _ package: AndroidSDKPackage) async throws {
        let target = destination(of: package)
        try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard case .sdk = package.destination else {
            try fileManager.moveItem(at: file, to: target)
            return
        }
        // Next to the SDK, so the final move is a rename on the same volume.
        let staging = sdk.dataDirectory.appending(path: "staging")
        try? fileManager.removeItem(at: staging)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }
        // unzip keeps the executable bits and symlinks of the zip; ditto fails on zip64 entries like the 8.6 GB system.img.
        _ = try await runner.run(URL(filePath: "/usr/bin/unzip"), ["-q", file.path(percentEncoded: false), "-d", staging.path(percentEncoded: false)])
        let contents = try fileManager.contentsOfDirectory(atPath: staging.path(percentEncoded: false)).filter { $0 != "__MACOSX" }
        guard contents.count == 1, let folder = contents.first else { throw AndroidInstallerError.unexpectedArchive(package.name) }
        try fileManager.moveItem(at: staging.appending(path: folder), to: target)
    }

    private func writeAVD() throws {
        guard !exists(sdk.avd) else { return }
        try fileManager.createDirectory(at: sdk.avd, withIntermediateDirectories: true)
        try AndroidAVD.config(name: sdk.avdName).write(to: sdk.avd.appending(path: "config.ini"), atomically: true, encoding: .utf8)
        try AndroidAVD.pointer(avdHome: sdk.avdHome, name: sdk.avdName)
            .write(to: sdk.avdHome.appending(path: "\(sdk.avdName).ini"), atomically: true, encoding: .utf8)
    }
}
