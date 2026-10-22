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

    @Test func decodesMissingClickSoundAsOn() throws {
        let json = ##"{"id":"a","name":"A","url":"https://a.com","colorHex":"#000000","isDefault":false}"##
        let app = try JSONDecoder().decode(StreamingApp.self, from: Data(json.utf8))
        #expect(app.remoteClickSound)
    }

    @Test func roundTripsClickSoundOff() throws {
        var app = StreamingApp.android(package: "org.jellyfin.androidtv", name: "Jellyfin")
        app.remoteClickSound = false
        let decoded = try JSONDecoder().decode(StreamingApp.self, from: JSONEncoder().encode(app))
        #expect(!decoded.remoteClickSound)
    }

    @Test func webAppHasNoAndroidPackage() {
        #expect(DefaultApps.all[0].androidPackage == nil)
    }
}
