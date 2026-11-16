/// Carries the fraction of a pixel a scroll event cannot hold: the remote sends fractional deltas every frame,
/// and dropping the fractions slows a slow scroll down, or stops it (ADR 0012, 0015).
public struct ScrollCarry: Equatable, Sendable {
    private var dx = 0.0
    private var dy = 0.0

    public init() {}

    /// Adds a delta and returns the whole pixels to scroll now; the rest waits for the next delta.
    public mutating func add(dx: Double, dy: Double) -> (dx: Int32, dy: Int32) {
        self.dx += dx
        self.dy += dy
        let whole = (dx: self.dx.rounded(.towardZero), dy: self.dy.rounded(.towardZero))
        self.dx -= whole.dx
        self.dy -= whole.dy
        return (Int32(whole.dx), Int32(whole.dy))
    }
}
