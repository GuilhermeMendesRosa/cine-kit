import Foundation
import Testing
@testable import CineKitCore

struct RemotePairingTests {
    @Test func urlIsHostAndPortOnly() {
        #expect(RemotePairing.url(host: "sala.local", port: 8686).absoluteString == "http://sala.local:8686/")
    }
}
