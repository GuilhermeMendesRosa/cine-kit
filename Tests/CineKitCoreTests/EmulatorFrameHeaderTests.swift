import Foundation
import Testing
@testable import CineKitCore

struct EmulatorFrameHeaderTests {
    // width 1920, height 1080, fps 60, frame 11, timestamp — little-endian, as read from videmulator5554.
    let bytes = Data([
        0x80, 0x07, 0, 0, 0x38, 0x04, 0, 0, 60, 0, 0, 0, 11, 0, 0, 0,
        0x04, 0x6E, 0x5B, 0x1F, 0x2E, 0x5E, 0x06, 0,
    ])

    @Test func parsesSizeAndFrameNumber() {
        let header = bytes.withUnsafeBytes { EmulatorFrameHeader($0, regionSize: 8_306_688) }
        #expect(header == EmulatorFrameHeader(width: 1920, height: 1080, frameNumber: 11))
    }

    @Test func rejectsFrameLargerThanRegion() {
        let header = bytes.withUnsafeBytes { EmulatorFrameHeader($0, regionSize: 1_000_000) }
        #expect(header == nil)
    }
}
