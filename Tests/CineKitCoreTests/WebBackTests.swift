import Testing
@testable import CineKitCore

struct WebBackTests {
    @Test func fullscreenExitsFullscreenFirst() {
        #expect(WebBack.action(isFullscreen: true, handlesBack: true, canGoBack: true) == .exitFullscreen)
    }

    @Test func profileThatHandlesBackGetsBackspace() {
        #expect(WebBack.action(isFullscreen: false, handlesBack: true, canGoBack: true) == .sendBackspace)
    }

    @Test func historyGoesBack() {
        #expect(WebBack.action(isFullscreen: false, handlesBack: false, canGoBack: true) == .goBack)
    }

    @Test func noHistoryExits() {
        #expect(WebBack.action(isFullscreen: false, handlesBack: false, canGoBack: false) == .exit)
    }
}
