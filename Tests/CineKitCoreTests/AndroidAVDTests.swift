import Foundation
import Testing
@testable import CineKitCore

struct AndroidAVDTests {
    @Test func configPointsAtThePinnedTVImageWith2GBOfRAM() {
        let lines = AndroidAVD.config(name: "cinekit-tv").split(separator: "\n")

        #expect(lines.contains("image.sysdir.1=system-images/android-36/android-tv/arm64-v8a/"))
        #expect(lines.contains("hw.ramSize=2048"))
        #expect(lines.contains("hw.dPad=yes"))
        #expect(lines.contains("avd.name=cinekit-tv"))
    }

    @Test func pointerUsesTheAbsoluteAVDPath() {
        let pointer = AndroidAVD.pointer(avdHome: URL(filePath: "/Users/me/.android/avd"), name: "cinekit-tv")

        #expect(pointer.contains("path=/Users/me/.android/avd/cinekit-tv.avd\n"))
        #expect(pointer.contains("target=android-36"))
    }

    @Test func pinnedSystemImageGoesWhereTheAVDLooks() {
        #expect(AndroidSDKPackage.pinned.contains { $0.destination == .sdk(AndroidAVD.systemImage) })
    }
}
