/// Header of the framebuffer the emulator shares with `-share-vid` (ADR 0009): width, height, fps and frame number
/// as little-endian `UInt32`, a `UInt64` timestamp, then `width × height` RGBA8888 pixels.
public struct EmulatorFrameHeader: Equatable, Sendable {
    /// `videmulator<console port>`; the console port of `emulator-5554` is 5554.
    public static let sharedMemoryName = "videmulator5554"
    public static let size = 24

    public let width: Int
    public let height: Int
    public let frameNumber: UInt32

    public init(width: Int, height: Int, frameNumber: UInt32) {
        self.width = width
        self.height = height
        self.frameNumber = frameNumber
    }

    /// Nil when the pixels would not fit in the region: the layout changed in another emulator version.
    public init?(_ bytes: UnsafeRawBufferPointer, regionSize: Int) {
        guard bytes.count >= Self.size else { return nil }
        let field = { (offset: Int) in Int(UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self))) }
        let width = field(0)
        let height = field(4)
        guard width > 0, height > 0, Self.size + width * height * 4 <= regionSize else { return nil }
        self.init(width: width, height: height, frameNumber: UInt32(field(12)))
    }
}
