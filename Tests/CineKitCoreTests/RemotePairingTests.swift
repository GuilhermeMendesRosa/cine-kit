import Foundation
import Testing
@testable import CineKitCore

struct RemotePairingTests {
    @Test func urlCarriesHostPortAndToken() {
        #expect(RemotePairing.url(host: "sala.local", port: 8686, token: "abc-_1").absoluteString == "http://sala.local:8686/?token=abc-_1")
    }

    @Test func tokensAreRandomAndUrlSafe() {
        let first = RemotePairing.makeToken()
        let second = RemotePairing.makeToken()
        #expect(first != second)
        #expect(first.count == 43)
        #expect(first.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
    }
}
