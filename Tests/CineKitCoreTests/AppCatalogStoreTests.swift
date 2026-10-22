import Foundation
import Testing
@testable import CineKitCore

struct AppCatalogStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: "CineKit Tests-\(UUID().uuidString)")

    private func makeStore() throws -> AppCatalogStore {
        let store = AppCatalogStore(directory: directory, now: { Date(timeIntervalSince1970: 1_700_000_000) })
        try store.load()
        return store
    }

    @Test func firstLoadSeedsDefaultsAndWritesFile() throws {
        let store = try makeStore()
        #expect(store.apps == DefaultApps.all)
        let data = try Data(contentsOf: directory.appending(path: "apps.json"))
        #expect(try JSONDecoder().decode([StreamingApp].self, from: data) == DefaultApps.all)
    }

    @Test func addPersistsAcrossInstances() throws {
        let custom = StreamingApp(id: "mubi", name: "Mubi", url: URL(string: "https://mubi.com")!, colorHex: "#000000", isDefault: false)
        try makeStore().add(custom)
        #expect(try makeStore().apps == DefaultApps.all + [custom])
    }

    @Test func updateDefaultAppPersists() throws {
        var netflix = DefaultApps.all[0]
        netflix.name = "Netflix Kids"
        try makeStore().update(netflix)
        #expect(try makeStore().apps[0].name == "Netflix Kids")
    }

    @Test func removeDefaultAppPersists() throws {
        try makeStore().remove(id: "netflix")
        #expect(try makeStore().apps == Array(DefaultApps.all.dropFirst()))
    }

    @Test func restoreDefaultsRevertsDefaultsAndKeepsCustom() throws {
        let store = try makeStore()
        var netflix = DefaultApps.all[0]
        netflix.name = "Netflix Kids"
        try store.update(netflix)
        try store.remove(id: "youtube")
        let custom = StreamingApp(id: "mubi", name: "Mubi", url: URL(string: "https://mubi.com")!, colorHex: "#000000", isDefault: false)
        try store.add(custom)

        try store.restoreDefaults()

        #expect(store.apps == DefaultApps.all + [custom])
        #expect(try makeStore().apps == DefaultApps.all + [custom])
    }

    @Test func corruptFileIsRenamedAndDefaultsLoaded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("lixo".utf8).write(to: directory.appending(path: "apps.json"))

        let store = try makeStore()

        #expect(store.apps == DefaultApps.all)
        let corrupt = directory.appending(path: "apps.json.corrupt-1700000000")
        #expect(try String(contentsOf: corrupt, encoding: .utf8) == "lixo")
    }

    @Test func importImageCopiesIntoImagesDirectory() throws {
        let store = try makeStore()
        let source = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
        try Data("png".utf8).write(to: source)

        let fileName = try store.importImage(from: source)

        #expect(fileName.hasSuffix(".png"))
        let copied = directory.appending(path: "images/\(fileName)")
        #expect(try Data(contentsOf: copied) == Data("png".utf8))
        var app = DefaultApps.all[0]
        app.imageFileName = fileName
        #expect(store.imageURL(for: app) == copied)
    }

    @Test func imageURLIsNilWhenFileMissing() throws {
        var app = DefaultApps.all[0]
        app.imageFileName = "missing.png"
        #expect(try makeStore().imageURL(for: app) == nil)
    }

    @Test func saveFailureThrowsAndKeepsMemoryState() throws {
        let store = try makeStore()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path(percentEncoded: false))
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path(percentEncoded: false)) }
        let custom = StreamingApp(id: "mubi", name: "Mubi", url: URL(string: "https://mubi.com")!, colorHex: "#000000", isDefault: false)

        #expect(throws: (any Error).self) { try store.add(custom) }
        #expect(store.apps.last == custom)
    }
}
