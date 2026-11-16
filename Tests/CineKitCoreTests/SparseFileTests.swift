import Foundation
import Testing
@testable import CineKitCore

struct SparseFileTests {
    let file = FileManager.default.temporaryDirectory.appending(path: "SparseFileTests-\(UUID().uuidString).img")

    private func allocatedSize() throws -> Int {
        try URL(filePath: file.path(percentEncoded: false)).resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0
    }

    @Test func keepsTheBytesAndFreesTheZeros() throws {
        defer { try? FileManager.default.removeItem(at: file) }
        // Data, a long run of zeros, data that ends mid-chunk, then zeros up to the end.
        var contents = Data("head".utf8) + Data(count: 32 << 20) + Data("tail".utf8)
        contents += Data(count: (3 << 20) + 123)
        try contents.write(to: file)

        try SparseFile.compact(file)

        #expect(try Data(contentsOf: file) == contents)
        #expect(try allocatedSize() < 8 << 20)
    }
}
