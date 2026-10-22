import Testing
@testable import CineKitCore

struct VolumeTests {
    @Test func stepsBySixteenthAndClamps() {
        #expect(Volume.step(0.5, direction: .up) == 0.5625)
        #expect(Volume.step(0.5, direction: .down) == 0.4375)
        #expect(Volume.step(0.97, direction: .up) == 1)
        #expect(Volume.step(0.03, direction: .down) == 0)
    }
}
