import Foundation
import Testing
@testable import CineKitCore

struct RecentWebAppsTests {
    @Test func touchPutsMostRecentFirst() {
        var recent = RecentWebApps(capacity: 3)

        #expect(recent.touch("a") == [])
        #expect(recent.touch("b") == [])
        #expect(recent.ids == ["b", "a"])
    }

    @Test func touchPastCapacityEvictsLeastRecent() {
        var recent = RecentWebApps(capacity: 3)
        _ = recent.touch("a")
        _ = recent.touch("b")
        _ = recent.touch("c")

        #expect(recent.touch("d") == ["a"])
        #expect(recent.ids == ["d", "c", "b"])
    }

    @Test func touchingExistingIdMovesItWithoutEvicting() {
        var recent = RecentWebApps(capacity: 3)
        _ = recent.touch("a")
        _ = recent.touch("b")
        _ = recent.touch("c")

        #expect(recent.touch("a") == [])
        #expect(recent.ids == ["a", "c", "b"])
    }

    @Test func removeDropsId() {
        var recent = RecentWebApps(capacity: 3)
        _ = recent.touch("a")
        _ = recent.touch("b")

        recent.remove("b")
        recent.remove("missing")

        #expect(recent.ids == ["a"])
    }

    @Test func staleFindsRemovedAndChangedApps() {
        let cached = [
            "a": URL(string: "https://a.example")!,
            "b": URL(string: "https://b.example")!,
            "c": URL(string: "https://c.example")!,
        ]
        let current = [
            StreamingApp(id: "a", name: "A", url: URL(string: "https://a.example")!, colorHex: "#000000", isDefault: true),
            StreamingApp(id: "b", name: "B", url: URL(string: "https://new-b.example")!, colorHex: "#000000", isDefault: true),
        ]

        #expect(Set(RecentWebApps.stale(cached: cached, current: current)) == ["b", "c"])
    }
}
