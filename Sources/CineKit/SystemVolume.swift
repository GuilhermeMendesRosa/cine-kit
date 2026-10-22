import CineKitCore
import AudioToolbox
import os

/// Volume and mute of the Mac's default output device, for the remote's volume buttons (ADR 0003).
enum SystemVolume {
    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "SystemVolume")

    static func adjust(_ direction: Volume.Direction) {
        guard let device = defaultOutputDevice(),
              let volume: Float32 = get(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, of: device) else { return }
        set(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, of: device, to: Volume.step(volume, direction: direction))
    }

    static func toggleMute() {
        guard let device = defaultOutputDevice(),
              let muted: UInt32 = get(kAudioDevicePropertyMute, of: device) else { return }
        set(kAudioDevicePropertyMute, of: device, to: UInt32(muted == 0 ? 1 : 0))
    }

    private static func defaultOutputDevice() -> AudioObjectID? {
        get(kAudioHardwarePropertyDefaultOutputDevice, of: AudioObjectID(kAudioObjectSystemObject), scope: kAudioObjectPropertyScopeGlobal)
    }

    private static func get<Value: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, of object: AudioObjectID, scope: AudioObjectPropertyScope = kAudioDevicePropertyScopeOutput) -> Value? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<Value>.size)
        let pointer = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        let status = AudioObjectGetPropertyData(object, &address, 0, nil, &size, pointer)
        guard status == noErr else {
            logger.error("Reading audio property \(selector) failed: \(status)")
            return nil
        }
        return pointer.pointee
    }

    private static func set<Value: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, of object: AudioObjectID, to value: Value) {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
        var value = value
        let status = AudioObjectSetPropertyData(object, &address, 0, nil, UInt32(MemoryLayout<Value>.size), &value)
        if status != noErr {
            logger.error("Writing audio property \(selector) failed: \(status)")
        }
    }
}
