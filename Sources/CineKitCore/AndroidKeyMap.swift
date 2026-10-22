public enum AndroidKeyAction: Equatable, Sendable {
    case key(Int32)
    case text(String)
}

/// Maps Mac keys to what a TV remote would send (ADR 0004).
public enum AndroidKeyMap {
    public enum Modifier: Sendable {
        case command
    }

    // Mac virtual key code → Android KeyEvent code.
    private static let keys: [UInt16: Int32] = [
        123: 21, // ← DPAD_LEFT
        124: 22, // → DPAD_RIGHT
        125: 20, // ↓ DPAD_DOWN
        126: 19, // ↑ DPAD_UP
        36: 23, // Return → DPAD_CENTER
        49: 85, // Space → MEDIA_PLAY_PAUSE
        51: 67, // Delete → DEL
    ]
    private static let escapeKeyCode: UInt16 = 53

    /// Nil for Esc (handled by the screen), ⌘ shortcuts and keys with no printable text.
    public static func action(keyCode: UInt16, characters: String?, modifiers: Set<Modifier>) -> AndroidKeyAction? {
        guard !modifiers.contains(.command), keyCode != escapeKeyCode else { return nil }
        if let key = keys[keyCode] { return .key(key) }
        // Function keys arrive as private-use characters and Control combinations as control characters.
        guard let characters, !characters.isEmpty, characters.unicodeScalars.allSatisfy({
            ![.control, .privateUse].contains($0.properties.generalCategory)
        }) else { return nil }
        return .text(characters)
    }
}
