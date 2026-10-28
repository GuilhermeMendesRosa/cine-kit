import Foundation

/// The sleep timer set from the remote: when it runs out, the app turns off (ADR 0024).
public struct SleepTimer: Equatable, Sendable {
    /// The minutes the remote offers, like a TV's sleep button.
    public static let options = [15, 30, 45, 60, 90, 120]

    public private(set) var deadline: Date?

    public init() {}

    /// Sets the timer to `minutes` from `now`, replacing the current one. `0` cancels it.
    public mutating func start(minutes: Int, now: Date) {
        deadline = minutes == 0 ? nil : now + TimeInterval(minutes * 60)
    }

    public mutating func cancel() {
        deadline = nil
    }

    /// The seconds left, rounded up, or `nil` with no timer or after the deadline.
    public func remaining(at now: Date) -> Int? {
        guard let deadline, deadline > now else { return nil }
        return Int(ceil(deadline.timeIntervalSince(now)))
    }
}
