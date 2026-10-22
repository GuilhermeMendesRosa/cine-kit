import Foundation
import Observation
import os

@Observable
public final class AppCatalogStore {
    public private(set) var apps: [StreamingApp] = []

    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "AppCatalogStore")

    private let directory: URL
    private let now: () -> Date

    private var fileURL: URL { directory.appending(path: "apps.json") }
    private var imagesDirectory: URL { directory.appending(path: "images") }

    public init(directory: URL, now: @escaping () -> Date = Date.init) {
        self.directory = directory
        self.now = now
    }

    public func load() throws {
        if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            let data = try Data(contentsOf: fileURL)
            do {
                apps = try JSONDecoder().decode([StreamingApp].self, from: data)
                return
            } catch {
                let corruptURL = directory.appending(path: "apps.json.corrupt-\(Int(now().timeIntervalSince1970))")
                try FileManager.default.moveItem(at: fileURL, to: corruptURL)
                Self.logger.error("Corrupt apps.json moved to \(corruptURL.path(percentEncoded: false), privacy: .public): \(error)")
            }
        }
        apps = DefaultApps.all
        try save()
    }

    public func add(_ app: StreamingApp) throws {
        apps.append(app)
        try save()
    }

    public func update(_ app: StreamingApp) throws {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        apps[index] = app
        try save()
    }

    public func remove(id: StreamingApp.ID) throws {
        apps.removeAll { $0.id == id }
        try save()
    }

    public func restoreDefaults() throws {
        apps = DefaultApps.all + apps.filter { !$0.isDefault }
        try save()
    }

    public func importImage(from source: URL) throws -> String {
        let fileName = "\(UUID().uuidString).\(source.pathExtension)"
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: source, to: imagesDirectory.appending(path: fileName))
        return fileName
    }

    public func imageURL(for app: StreamingApp) -> URL? {
        guard let fileName = app.imageFileName else { return nil }
        let url = imagesDirectory.appending(path: fileName)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(apps).write(to: fileURL, options: .atomic)
    }
}
