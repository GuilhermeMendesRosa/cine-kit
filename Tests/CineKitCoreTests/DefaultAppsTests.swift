import Testing
@testable import CineKitCore

struct DefaultAppsTests {
    @Test func hasSixAppsWithUniqueIds() {
        let ids = DefaultApps.all.map(\.id)
        #expect(ids == ["netflix", "prime-video", "disney-plus", "hbo-max", "globoplay", "youtube"])
    }

    @Test func allUrlsAreHttps() {
        #expect(DefaultApps.all.allSatisfy { $0.url.scheme == "https" && $0.url.host() != nil })
    }

    @Test func allAreMarkedDefaultWithValidColor() {
        for app in DefaultApps.all {
            #expect(app.isDefault)
            #expect(app.colorHex.wholeMatch(of: /#[0-9A-Fa-f]{6}/) != nil)
        }
    }
}
