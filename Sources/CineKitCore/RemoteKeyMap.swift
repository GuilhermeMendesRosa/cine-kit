public struct Keystroke: Equatable, Sendable {
    public let keyCode: UInt16
    public let command: Bool
    public let isDown: Bool
    public let isRepeat: Bool
}

/// Maps remote buttons to the same Mac keys in every screen (ADR 0012).
public enum RemoteKeyMap {
    // Remote button → Mac virtual key code.
    private static let keys: [RemoteButton: UInt16] = [
        .left: 123, // ←
        .right: 124, // →
        .down: 125, // ↓
        .up: 126, // ↑
        .ok: 36, // Return
        .playPause: 49, // Space
        .delete: 51, // Delete
    ]
    private static let escapeKeyCode: UInt16 = 53

    /// Empty for the volume and power buttons, which the server handles itself.
    public static func keystrokes(for button: RemoteButton) -> [Keystroke] {
        switch button {
        case .back:
            press(escapeKeyCode)
        case .home:
            // A held Esc: app screens leave on the repeat; elsewhere the first Esc already goes home.
            [
                Keystroke(keyCode: escapeKeyCode, command: false, isDown: true, isRepeat: false),
                Keystroke(keyCode: escapeKeyCode, command: false, isDown: true, isRepeat: true),
                Keystroke(keyCode: escapeKeyCode, command: false, isDown: false, isRepeat: false),
            ]
        case .volumeUp, .volumeDown, .mute, .power:
            []
        default:
            keys[button].map { press($0) } ?? []
        }
    }

    private static func press(_ keyCode: UInt16, command: Bool = false) -> [Keystroke] {
        [
            Keystroke(keyCode: keyCode, command: command, isDown: true, isRepeat: false),
            Keystroke(keyCode: keyCode, command: command, isDown: false, isRepeat: false),
        ]
    }
}
