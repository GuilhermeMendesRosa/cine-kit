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
}
