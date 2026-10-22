import Testing
@testable import CineKitCore

struct EmulatorPointerTests {
    @Test func mapsCenterOfFullView() throws {
        let point = try #require(EmulatorPointer.devicePoint(x: 960, y: 540, viewWidth: 1920, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080))
        #expect(point.x == 960 && point.y == 540)
    }

    @Test func scalesViewToFrame() throws {
        let point = try #require(EmulatorPointer.devicePoint(x: 480, y: 135, viewWidth: 960, viewHeight: 540, frameWidth: 3840, frameHeight: 2160))
        #expect(point.x == 1920 && point.y == 540)
    }

    @Test func letterboxBarsAreNil() throws {
        // A 2000-wide view shows the 1920-wide frame with 40-point bars on each side.
        #expect(EmulatorPointer.devicePoint(x: 20, y: 500, viewWidth: 2000, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080) == nil)
        #expect(EmulatorPointer.devicePoint(x: 1990, y: 500, viewWidth: 2000, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080) == nil)
        let corner = try #require(EmulatorPointer.devicePoint(x: 40, y: 0, viewWidth: 2000, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080))
        #expect(corner.x == 0 && corner.y == 0)
    }

    @Test func outsideViewIsNil() {
        #expect(EmulatorPointer.devicePoint(x: -1, y: 10, viewWidth: 1920, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080) == nil)
        #expect(EmulatorPointer.devicePoint(x: 10, y: 1080, viewWidth: 1920, viewHeight: 1080, frameWidth: 1920, frameHeight: 1080) == nil)
    }
}
