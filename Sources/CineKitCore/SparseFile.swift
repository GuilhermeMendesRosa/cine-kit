import Foundation

/// Frees the zero-filled stretches of a file in place: same bytes, less disk.
/// The Android system image is 8.6 GB long with 1.7 GB of data (ADR 0018).
public enum SparseFile {
    /// A multiple of the file system block, which the holes must align to.
    private static let chunkSize = 1 << 20

    public static func compact(_ url: URL) throws {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        var offset: off_t = 0
        var zerosStart: off_t?
        var atEnd = false
        while !atEnd {
            try autoreleasepool {
                let chunk = try handle.read(upToCount: chunkSize) ?? Data()
                if chunk.count == chunkSize, isZero(chunk) {
                    zerosStart = zerosStart ?? offset
                } else if let start = zerosStart {
                    try punchHole(in: handle, from: start, to: offset)
                    zerosStart = nil
                }
                offset += off_t(chunk.count)
                atEnd = chunk.isEmpty
            }
        }
    }

    /// Copying around the zeros instead does not work: APFS fills the hole in when data is written after it.
    private static func punchHole(in handle: FileHandle, from start: off_t, to end: off_t) throws {
        var hole = fpunchhole_t(fp_flags: 0, reserved: 0, fp_offset: start, fp_length: end - start)
        guard fcntl(handle.fileDescriptor, F_PUNCHHOLE, &hole) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }

    private static func isZero(_ chunk: Data) -> Bool {
        chunk.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress, bytes[0] == 0 else { return false }
            // Every byte equal to the one before it, and the first is zero.
            return memcmp(base, base + 1, bytes.count - 1) == 0
        }
    }
}
