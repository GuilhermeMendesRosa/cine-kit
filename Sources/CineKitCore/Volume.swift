public enum Volume {
    public enum Direction: Sendable {
        case up, down
    }

    private static let increment: Float = 1.0 / 16

    /// The next output volume (0…1) after a Vol+ or Vol− press.
    public static func step(_ volume: Float, direction: Direction) -> Float {
        let next = direction == .up ? volume + increment : volume - increment
        return min(1, max(0, next))
    }
}
