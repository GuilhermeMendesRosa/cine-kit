import Foundation
import Testing
@testable import CineKitCore

struct AndroidIdentityTests {
    @Test func randomPicksAProfileWithA16CharacterSerial() {
        let identity = AndroidIdentity.random()

        #expect(AndroidIdentity.profiles.contains { $0.fingerprint == identity.fingerprint && $0.model == identity.model })
        #expect(identity.serial.count == 16)
        #expect(identity.serial.allSatisfy { $0.isHexDigit && !$0.isLowercase })
    }

    @Test func profilesAreReleaseBuilds() {
        #expect(AndroidIdentity.profiles.allSatisfy { $0.fingerprint.hasSuffix(":user/release-keys") })
    }

    @Test func buildPropSetsTheTopLevelProductPropsAndFingerprint() {
        let lines = AndroidIdentity.profiles[0].buildProp.split(separator: "\n")

        #expect(lines.contains("ro.product.model=Chromecast"))
        #expect(lines.contains("ro.product.device=sabrina"))
        #expect(lines.contains("ro.build.fingerprint=google/sabrina_prod_stable/sabrina:12/STTE.220920.016.H1/9408258:user/release-keys"))
    }

    @Test func ramdiskKeepsTheStockOneAndAppendsAnLZ4Frame() {
        let stock = Data([1, 2, 3, 4])

        let ramdisk = AndroidIdentity.profiles[0].ramdisk(appendingTo: stock)

        #expect(ramdisk.prefix(4) == stock)
        #expect(ramdisk.dropFirst(4).prefix(4) == Data([0x02, 0x21, 0x4C, 0x18]))
    }

    @Test func cpioEntriesAre4ByteAlignedAndEndWithTheTrailer() {
        let archive = Cpio.newc([.directory("system"), .file("system/a", Data("hello".utf8))])
        let text = String(decoding: archive, as: UTF8.self)

        #expect(archive.count % 4 == 0)
        #expect(text.hasPrefix("070701"))
        #expect(text.contains("system/a\0"))
        #expect(text.contains("hello"))
        #expect(text.contains("TRAILER!!!\0"))
    }

    @Test func lz4LiteralLengthOver15UsesExtraBytes() {
        let frame = LZ4Legacy.frame(Data(count: 300))

        // Magic, block size, token 0xF0, then 300 - 15 = 285 as 255 + 30.
        #expect(frame.count == 4 + 4 + 3 + 300)
        #expect(frame.dropFirst(4).prefix(4) == Data([0x2F, 0x01, 0, 0]))
        #expect(Array(frame.dropFirst(8).prefix(3)) == [0xF0, 255, 30])
    }
}
