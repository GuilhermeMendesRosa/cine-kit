import Foundation

/// A real Android TV's build props plus a random serial, so the emulator reads as that device.
/// The TV image is a `user` build without root, so the props ride on an extra ramdisk archive:
/// init loads its `build.prop` at boot, and the serial goes in `-android-serialno`.
public struct AndroidIdentity: Codable, Equatable, Sendable {
    public var brand: String
    public var manufacturer: String
    public var model: String
    public var device: String
    public var name: String
    public var fingerprint: String
    public var serial: String

    /// Fingerprints read from real devices (public bug reports and firmware dumps).
    public static let profiles = [
        AndroidIdentity(
            brand: "google", manufacturer: "Google", model: "Chromecast", device: "sabrina", name: "sabrina_prod_stable",
            fingerprint: "google/sabrina_prod_stable/sabrina:12/STTE.220920.016.H1/9408258:user/release-keys", serial: ""
        ),
        AndroidIdentity(
            brand: "NVIDIA", manufacturer: "NVIDIA", model: "SHIELD Android TV", device: "mdarcy", name: "mdarcy",
            fingerprint: "NVIDIA/mdarcy/mdarcy:11/RQ1A.210105.003/7094531_2914.3416:user/release-keys", serial: ""
        ),
        AndroidIdentity(
            brand: "Xiaomi", manufacturer: "Xiaomi", model: "MiTV-AFMU0", device: "twilight", name: "twilight",
            fingerprint: "Xiaomi/twilight/twilight:14/UKG3.250826.001/V816.0.11.0.UZFAABX:user/release-keys", serial: ""
        ),
    ]

    public static func random() -> AndroidIdentity {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public static func random(using generator: inout some RandomNumberGenerator) -> AndroidIdentity {
        var identity = profiles.randomElement(using: &generator)!
        let characters = Array("0123456789ABCDEF")
        identity.serial = String((0..<16).map { _ in characters.randomElement(using: &generator)! })
        return identity
    }

    /// The partition `build.prop`s load after this one and win for keys they also set, such as
    /// `ro.product.vendor.model` and `ro.build.tags`; the keys below are the ones they leave alone.
    public var buildProp: String {
        [
            "ro.product.brand=\(brand)",
            "ro.product.manufacturer=\(manufacturer)",
            "ro.product.model=\(model)",
            "ro.product.device=\(device)",
            "ro.product.name=\(name)",
            "ro.build.fingerprint=\(fingerprint)",
        ].joined(separator: "\n") + "\n"
    }

    /// The stock ramdisk followed by an archive with `system/etc/ramdisk/build.prop`; the kernel unpacks both.
    public func ramdisk(appendingTo stock: Data) -> Data {
        let archive = Cpio.newc([
            .directory("system"),
            .directory("system/etc"),
            .directory("system/etc/ramdisk"),
            .file("system/etc/ramdisk/build.prop", Data(buildProp.utf8)),
        ])
        return stock + LZ4Legacy.frame(archive)
    }
}

/// The `newc` cpio format the kernel reads in an initramfs.
enum Cpio {
    enum Entry {
        case directory(String)
        case file(String, Data)
    }

    static func newc(_ entries: [Entry]) -> Data {
        var archive = Data()
        for (index, entry) in entries.enumerated() {
            switch entry {
            case .directory(let path): append(path, mode: 0o040755, data: Data(), inode: index + 1, to: &archive)
            case .file(let path, let data): append(path, mode: 0o100644, data: data, inode: index + 1, to: &archive)
            }
        }
        append("TRAILER!!!", mode: 0, data: Data(), inode: 0, to: &archive)
        return archive
    }

    private static func append(_ name: String, mode: Int, data: Data, inode: Int, to archive: inout Data) {
        let nameBytes = Data(name.utf8) + [0]
        let nlink = mode & 0o040000 != 0 ? 2 : 1
        // ino, mode, uid, gid, nlink, mtime, filesize, devmajor, devminor, rdevmajor, rdevminor, namesize, check.
        let fields = [inode, mode, 0, 0, nlink, 0, data.count, 0, 0, 0, 0, nameBytes.count, 0]
        archive += Data(("070701" + fields.map { String(format: "%08X", $0) }.joined()).utf8)
        archive += nameBytes
        pad(&archive)
        archive += data
        pad(&archive)
    }

    private static func pad(_ archive: inout Data) {
        archive += Data(count: (4 - archive.count % 4) % 4)
    }
}

/// The legacy LZ4 frame the emulator's ramdisk uses, holding one literal-only block: valid LZ4, just not compressed.
enum LZ4Legacy {
    static func frame(_ data: Data) -> Data {
        var block = Data()
        let length = data.count
        block.append(UInt8(min(length, 15)) << 4)
        if length >= 15 {
            var remaining = length - 15
            while remaining >= 255 {
                block.append(255)
                remaining -= 255
            }
            block.append(UInt8(remaining))
        }
        block += data
        return littleEndian(0x184C_2102) + littleEndian(UInt32(block.count)) + block
    }

    private static func littleEndian(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
}
