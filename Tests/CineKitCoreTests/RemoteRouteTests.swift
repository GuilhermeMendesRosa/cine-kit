import Foundation
import Testing
@testable import CineKitCore

struct RemoteRouteTests {
    private let files = [
        "index.html": Data("<html>".utf8),
        "assets/app.js": Data("js".utf8),
    ]

    private func respond(_ raw: String) throws -> RemoteResponse {
        let request = try #require(RemoteHTTPRequest.parse(Data(raw.utf8)))
        return RemoteRoute.response(for: request, token: "secret") { files[$0] }
    }

    private func press(_ body: String, authorization: String? = "Bearer secret") throws -> RemoteResponse {
        let header = authorization.map { "Authorization: \($0)\r\n" } ?? ""
        return try respond("POST /api/press HTTP/1.1\r\n\(header)Content-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    @Test func rootServesIndex() throws {
        let response = try respond("GET /?token=abc HTTP/1.1\r\n\r\n")
        #expect(response.status == 200)
        #expect(response.headers["Content-Type"] == "text/html; charset=utf-8")
        #expect(response.body == Data("<html>".utf8))
    }

    @Test func servesAssetWithContentType() throws {
        let response = try respond("GET /assets/app.js HTTP/1.1\r\n\r\n")
        #expect(response.status == 200)
        #expect(response.headers["Content-Type"] == "text/javascript; charset=utf-8")
        #expect(response.body == Data("js".utf8))
    }

    @Test func unknownPathIs404() throws {
        #expect(try respond("GET /missing.png HTTP/1.1\r\n\r\n").status == 404)
        #expect(try respond("POST /api/other HTTP/1.1\r\n\r\n").status == 404)
    }

    @Test func pressWithoutTokenIs401() throws {
        #expect(try press(#"{"button":"ok"}"#, authorization: nil).status == 401)
    }

    @Test func pressWithWrongTokenIs401() throws {
        #expect(try press(#"{"button":"ok"}"#, authorization: "Bearer wrong").status == 401)
    }

    @Test func unknownButtonIs400() throws {
        let response = try press(#"{"button":"power"}"#)
        #expect(response.status == 400)
        #expect(response.button == nil)
    }

    @Test func validPressReturns204AndButton() throws {
        let response = try press(#"{"button":"playPause"}"#)
        #expect(response.status == 204)
        #expect(response.button == .playPause)
    }

    @Test func rejectsPathTraversal() throws {
        let request = try #require(RemoteHTTPRequest.parse(Data("GET /../secret.txt HTTP/1.1\r\n\r\n".utf8)))
        var asked = false
        let response = RemoteRoute.response(for: request, token: "secret") { _ in
            asked = true
            return Data()
        }
        #expect(response.status == 404)
        #expect(!asked)
    }
}
