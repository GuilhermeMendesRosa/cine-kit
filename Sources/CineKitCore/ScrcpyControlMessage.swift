import Foundation

/// Control messages of the scrcpy-server v5.0.1 protocol (`ControlMessageReader.java`), big-endian.
public enum ScrcpyControlMessage: Equatable, Sendable {
    public enum KeyAction: UInt8, Sendable {
        case down = 0, up = 1
    }

    public enum TouchAction: UInt8, Sendable {
        case down = 0, up = 1, move = 2
    }

    private static let genericFingerPointerId: Int64 = -2
    private static let maxScroll: Float = 16

    case injectKeycode(action: KeyAction, keycode: Int32, repeat: Int32 = 0, metaState: Int32 = 0)
    case injectText(String)
    case injectTouch(action: TouchAction, x: Int32, y: Int32, width: UInt16, height: UInt16)
    /// Scroll amounts in [-16, 16]; larger ones are clamped.
    case injectScroll(x: Int32, y: Int32, width: UInt16, height: UInt16, horizontal: Float, vertical: Float)

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
        case .injectTouch(let action, let x, let y, let width, let height):
            data.append(2)
            data.append(action.rawValue)
            data.append(contentsOf: withUnsafeBytes(of: Self.genericFingerPointerId.bigEndian, Array.init))
            data.append(Self.position(x: x, y: y, width: width, height: height))
            let pressure: UInt16 = action == .up ? 0 : 0xFFFF
            data.append(contentsOf: withUnsafeBytes(of: pressure.bigEndian, Array.init))
            // Action button and buttons: none, as a finger.
            data.append(contentsOf: [UInt8](repeating: 0, count: 8))
        case .injectScroll(let x, let y, let width, let height, let horizontal, let vertical):
            data.append(3)
            data.append(Self.position(x: x, y: y, width: width, height: height))
            for amount in [horizontal, vertical] {
                data.append(contentsOf: withUnsafeBytes(of: Self.fixedPoint(amount).bigEndian, Array.init))
            }
            // Buttons: none.
            data.append(contentsOf: [UInt8](repeating: 0, count: 4))
        }
        return data
    }

    private static func position(x: Int32, y: Int32, width: UInt16, height: UInt16) -> Data {
        var data = Data()
        for value in [x, y] {
            data.append(contentsOf: withUnsafeBytes(of: value.bigEndian, Array.init))
        }
        for value in [width, height] {
            data.append(contentsOf: withUnsafeBytes(of: value.bigEndian, Array.init))
        }
        return data
    }

    /// The server reads scroll as a 16-bit fixed-point fraction of 16.
    private static func fixedPoint(_ amount: Float) -> Int16 {
        let normalized = min(max(amount, -maxScroll), maxScroll) / maxScroll
        return Int16(min(max(Int32(normalized * 32768), -0x8000), 0x7FFF))
    }
}
