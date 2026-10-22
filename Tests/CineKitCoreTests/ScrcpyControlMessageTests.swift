import Foundation
import Testing
@testable import CineKitCore

struct ScrcpyControlMessageTests {
    @Test func injectKeycodeEncodesBigEndian() {
        let message = ScrcpyControlMessage.injectKeycode(action: .down, keycode: 23)
        #expect(message.encoded == Data([0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0]))
    }

    @Test func injectTextEncodesLengthAndUtf8() {
        let message = ScrcpyControlMessage.injectText("ã")
        #expect(message.encoded == Data([1, 0, 0, 0, 2, 0xC3, 0xA3]))
    }

    @Test func injectTouchDownEncodes32Bytes() {
        let message = ScrcpyControlMessage.injectTouch(action: .down, x: 100, y: 200, width: 1920, height: 1080)
        #expect(message.encoded == Data([
            2, 0,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, // generic finger
            0, 0, 0, 100, 0, 0, 0, 200, 0x07, 0x80, 0x04, 0x38,
            0xFF, 0xFF,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]))
    }

    @Test func injectTouchUpHasZeroPressure() {
        let encoded = ScrcpyControlMessage.injectTouch(action: .up, x: 100, y: 200, width: 1920, height: 1080).encoded
        #expect(encoded[1] == 1)
        #expect(encoded[22..<24] == Data([0, 0]))
    }

    @Test func injectScrollEncodesFixedPoint() {
        let message = ScrcpyControlMessage.injectScroll(x: 10, y: 20, width: 1920, height: 1080, horizontal: -8, vertical: 8)
        #expect(message.encoded == Data([
            3,
            0, 0, 0, 10, 0, 0, 0, 20, 0x07, 0x80, 0x04, 0x38,
            0xC0, 0x00, 0x40, 0x00,
            0, 0, 0, 0,
        ]))
    }

    @Test func injectScrollClampsToSixteen() {
        let encoded = ScrcpyControlMessage.injectScroll(x: 0, y: 0, width: 1920, height: 1080, horizontal: -100, vertical: 100).encoded
        #expect(encoded[13..<17] == Data([0x80, 0x00, 0x7F, 0xFF]))
    }
}
