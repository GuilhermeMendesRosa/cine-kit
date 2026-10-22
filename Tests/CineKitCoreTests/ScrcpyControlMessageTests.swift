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
}
