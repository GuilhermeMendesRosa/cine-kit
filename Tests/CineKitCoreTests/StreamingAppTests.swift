import Foundation
import Testing
@testable import CineKitCore

struct StreamingAppTests {
    @Test func androidAppExposesPackage() {
        let app = StreamingApp.android(package: "org.jellyfin.androidtv", name: "Jellyfin")
        #expect(app.androidPackage == "org.jellyfin.androidtv")
        #expect(app.url.absoluteString == "android-app://org.jellyfin.androidtv")
        #expect(app.name == "Jellyfin")
        #expect(app.colorHex == "#5E5CE6")
        #expect(!app.isDefault)
    }

    @Test func webAppHasNoAndroidPackage() {
        #expect(DefaultApps.all[0].androidPackage == nil)
    }
}
