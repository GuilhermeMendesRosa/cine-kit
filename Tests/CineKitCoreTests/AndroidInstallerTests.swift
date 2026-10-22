import CryptoKit
import Foundation
import Testing
@testable import CineKitCore

/// Serves `contents` keyed by URL, written to a fresh file like URLSession does.
private final class FakeDownloader: Downloader, @unchecked Sendable {
    var contents: [URL: Data] = [:]
    var downloaded: [URL] = []
    let directory: URL

    init(directory: URL) { self.directory = directory }

    func download(_ url: URL, progress: @escaping @Sendable (Int64) -> Void) async throws -> URL {
        downloaded.append(url)
        let data = contents[url] ?? Data()
        let file = directory.appending(path: UUID().uuidString)
        try data.write(to: file)
        progress(Int64(data.count))
        return file
    }
}

/// Stands in for ditto: unpacks every zip as `<folder>/source.properties`.
private final class FakeExtractor: CommandRunner, @unchecked Sendable {
    var folder = "android-15"

    func run(_ executable: URL, _ arguments: [String]) async throws -> String {
        let staging = URL(filePath: arguments[3]).appending(path: folder)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        try Data("Pkg.Revision=35.0.0".utf8).write(to: staging.appending(path: "source.properties"))
        return ""
    }

    func launch(_ executable: URL, _ arguments: [String]) throws -> RunningProcess { fatalError("unused") }
}

@MainActor
struct AndroidInstallerTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: "AndroidInstallerTests-\(UUID().uuidString)")
    let sdk: AndroidSDK
    fileprivate let downloader: FakeDownloader
    fileprivate let extractor = FakeExtractor()

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        sdk = AndroidSDK(root: directory.appending(path: "android/sdk"), dataDirectory: directory.appending(path: "android"), avdHome: directory.appending(path: "avd"))
        downloader = FakeDownloader(directory: directory)
    }

    private func package(_ name: String, _ data: Data, _ destination: AndroidSDKPackage.Destination, sha1: String? = nil) -> AndroidSDKPackage {
        let url = URL(string: "https://example.com/\(name)")!
        downloader.contents[url] = data
        let digest = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return AndroidSDKPackage(name: name, url: url, checksum: .sha1(sha1 ?? digest), size: Int64(data.count), destination: destination)
    }

    private func installer(_ packages: [AndroidSDKPackage]) -> AndroidInstaller {
        AndroidInstaller(sdk: sdk, packages: packages, downloader: downloader, runner: extractor)
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    @Test func movesTheZipTopLevelFolderToItsSDKPath() async throws {
        try await installer([package("build-tools", Data("zip".utf8), .sdk("build-tools/35.0.0"))]).install()

        #expect(exists(sdk.root.appending(path: "build-tools/35.0.0/source.properties")))
        #expect(!exists(sdk.dataDirectory.appending(path: "staging")))
    }

    @Test func movesAPlainFileToTheScrcpyServerPath() async throws {
        let sha256 = SHA256.hash(data: Data("jar".utf8)).map { String(format: "%02x", $0) }.joined()
        let url = URL(string: "https://example.com/scrcpy-server")!
        downloader.contents[url] = Data("jar".utf8)

        try await installer([AndroidSDKPackage(name: "scrcpy-server", url: url, checksum: .sha256(sha256), size: 3, destination: .scrcpyServer)]).install()

        #expect(try Data(contentsOf: sdk.scrcpyServer) == Data("jar".utf8))
    }

    @Test func skipsPackagesAlreadyInPlace() async throws {
        try FileManager.default.createDirectory(at: sdk.root.appending(path: "emulator"), withIntermediateDirectories: true)
        let emulator = package("emulator", Data("zip".utf8), .sdk("emulator"))
        let tools = package("platform-tools", Data("zip".utf8), .sdk("platform-tools"))

        try await installer([emulator, tools]).install()

        #expect(downloader.downloaded == [tools.url])
    }

    @Test func checksumMismatchThrowsAndLeavesNothingBehind() async throws {
        let broken = package("emulator", Data("zip".utf8), .sdk("emulator"), sha1: "0000")

        await #expect(throws: AndroidInstallerError.checksumMismatch("emulator")) {
            try await installer([broken]).install()
        }
        // Neither the download nor a half-installed package stays on disk.
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)).isEmpty)
    }

    @Test func writesTheAVDOnce() async throws {
        let installer = installer([])
        try await installer.install()
        let config = sdk.avd.appending(path: "config.ini")
        try Data("edited".utf8).write(to: config)

        try await installer.install()

        #expect(try String(contentsOf: sdk.avdHome.appending(path: "cinekit-tv.ini"), encoding: .utf8).contains("path.rel=avd/cinekit-tv.avd"))
        #expect(try String(contentsOf: config, encoding: .utf8) == "edited")
    }

    @Test func endsIdle() async throws {
        let installer = installer([package("platform-tools", Data("zip".utf8), .sdk("platform-tools"))])

        try await installer.install()

        #expect(installer.state == .idle)
    }
}
