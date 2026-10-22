import Foundation

/// The web services kept alive in the background, most recent first (ADR 0014).
public struct RecentWebApps: Equatable, Sendable {
    public private(set) var ids: [StreamingApp.ID] = []
    private let capacity: Int

    public init(capacity: Int) {
        self.capacity = capacity
    }

    /// Moves `id` to the front and returns the ids evicted past the capacity.
    public mutating func touch(_ id: StreamingApp.ID) -> [StreamingApp.ID] {
        remove(id)
        ids.insert(id, at: 0)
        let evicted = Array(ids.dropFirst(capacity))
        ids.removeLast(evicted.count)
        return evicted
    }

    public mutating func remove(_ id: StreamingApp.ID) {
        ids.removeAll { $0 == id }
    }

    /// Cached ids whose app was removed or now points at another URL.
    public static func stale(cached: [StreamingApp.ID: URL], current: [StreamingApp]) -> [StreamingApp.ID] {
        let urls = Dictionary(current.map { ($0.id, $0.url) }) { first, _ in first }
        return cached.filter { urls[$0.key] != $0.value }.map(\.key)
    }
}
