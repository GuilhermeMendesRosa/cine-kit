import Foundation

/// The files `avdmanager create avd -d tv_1080p` writes for the cinekit-tv AVD (ADR 0004, 0018).
public enum AndroidAVD {
    public static let systemImage = "system-images/android-36/android-tv/arm64-v8a"

    /// `<name>.ini`, next to the `<name>.avd` folder.
    public static func pointer(avdHome: URL, name: String) -> String {
        """
        avd.ini.encoding=UTF-8
        path=\(avdHome.appending(path: "\(name).avd").path(percentEncoded: false))
        path.rel=avd/\(name).avd
        target=android-36

        """
    }

    public static func config(name: String) -> String {
        [
            "PlayStore.enabled=no",
            "abi.type=arm64-v8a",
            "avd.ini.encoding=UTF-8",
            "avd.name=\(name)",
            "disk.dataPartition.size=4G",
            "fastboot.forceFastBoot=yes",
            "firstboot.bootFromLocalSnapshot=yes",
            "firstboot.saveToLocalSnapshot=yes",
            "hw.accelerometer=no",
            "hw.audioInput=yes",
            "hw.audioOutput=yes",
            "hw.battery=no",
            "hw.camera.back=emulated",
            "hw.camera.front=none",
            "hw.cpu.arch=arm64",
            "hw.cpu.ncore=4",
            "hw.dPad=yes",
            "hw.device.manufacturer=Google",
            "hw.device.name=tv_1080p",
            "hw.gps=yes",
            "hw.gpu.enabled=no",
            "hw.gpu.mode=auto",
            "hw.gyroscope=no",
            "hw.keyboard=no",
            "hw.lcd.density=320",
            "hw.lcd.height=1080",
            "hw.lcd.width=1920",
            "hw.mainKeys=yes",
            "hw.ramSize=2048",
            "hw.screen=no-touch",
            "hw.sdCard=yes",
            "hw.trackBall=no",
            "image.sysdir.1=\(systemImage)/",
            "sdcard.size=512 MB",
            "tag.display=Android TV",
            "tag.id=android-tv",
            "target=android-36",
            "vm.heapSize=128M",
        ].joined(separator: "\n") + "\n"
    }
}
