import Foundation
import Testing
@testable import CineKitCore

struct WebProfileTests {
    @Test(arguments: ["https://www.youtube.com", "https://youtube.com"])
    func youtubeOpensTvUi(url: String) {
        let profile = WebProfile.for(URL(string: url)!)
        #expect(profile.url.absoluteString == "https://www.youtube.com/tv")
        #expect(profile.userAgent == WebProfile.tvUserAgent)
        #expect(!profile.usesSpatialNavigation)
    }

    @Test func otherServicesKeepUrlAndSpatialNavigation() {
        let url = URL(string: "https://www.netflix.com")!
        let profile = WebProfile.for(url)
        #expect(profile.url == url)
        #expect(profile.userAgent == nil)
        #expect(profile.usesSpatialNavigation)
    }

    @Test func youtubeHandlesBack() {
        #expect(WebProfile.for(URL(string: "https://www.youtube.com")!).handlesBack)
    }

    @Test func otherServicesDoNotHandleBack() {
        #expect(!WebProfile.for(URL(string: "https://www.netflix.com")!).handlesBack)
    }

    @Test(arguments: ["https://www.netflix.com", "https://netflix.com"])
    func netflixBypassesHousehold(url: String) {
        let url = URL(string: url)!
        let profile = WebProfile.for(url)
        #expect(profile.bypassesNetflixHousehold)
        #expect(profile.usesSpatialNavigation)
        #expect(profile.url == url)
    }

    @Test(arguments: ["https://www.youtube.com", "https://www.primevideo.com", "https://notnetflix.com"])
    func otherServicesDoNotBypassHousehold(url: String) {
        #expect(!WebProfile.for(URL(string: url)!).bypassesNetflixHousehold)
    }
}
