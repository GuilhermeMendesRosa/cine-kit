import Foundation

/// Control messages of the scrcpy-server v5.0.1 protocol (`ControlMessageReader.java`), big-endian.
public enum ScrcpyControlMessage: Equatable, Sendable {
    public enum KeyAction: UInt8, Sendable {
        case down = 0, up = 1
    }

    case injectKeycode(action: KeyAction, keycode: Int32, repeat: Int32 = 0, metaState: Int32 = 0)
    case injectText(String)

    public var encoded: Data {
        var data = Data()
        switch self {
        case .injectKeycode(let action, let keycode, let `repeat`, let metaState):
            data.append(0)
            data.append(action.rawValue)
            for value in [keycode, `repeat`, metaState] {
                data.append(contentsOf: withUnsafeBytes(of: value.bigEndian, Array.init))
            }
        case .injectText(let text):
            let utf8 = Data(text.utf8)
            data.append(1)
            data.append(contentsOf: withUnsafeBytes(of: UInt32(utf8.count).bigEndian, Array.init))
            data.append(utf8)
        }
        return data
    }
}
