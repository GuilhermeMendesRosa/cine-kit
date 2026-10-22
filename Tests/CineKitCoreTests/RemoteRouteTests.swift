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

    private func pointer(_ body: String, authorization: String? = "Bearer secret") throws -> RemoteResponse {
        let header = authorization.map { "Authorization: \($0)\r\n" } ?? ""
        return try respond("POST /api/pointer HTTP/1.1\r\n\(header)Content-Length: \(body.utf8.count)\r\n\r\n\(body)")
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

    @Test func pointerMoveReturns204AndEvent() throws {
        let response = try pointer(#"{"type":"move","dx":12.5,"dy":-3}"#)
        #expect(response.status == 204)
        #expect(response.pointer == .move(dx: 12.5, dy: -3))
        #expect(response.button == nil)
    }

    @Test func pointerClickReturns204() throws {
        let response = try pointer(#"{"type":"click"}"#)
        #expect(response.status == 204)
        #expect(response.pointer == .click)
    }

    @Test func pointerScrollReturns204() throws {
        let response = try pointer(#"{"type":"scroll","dx":0,"dy":40}"#)
        #expect(response.status == 204)
        #expect(response.pointer == .scroll(dx: 0, dy: 40))
    }

    @Test func pointerWithoutTokenIs401() throws {
        #expect(try pointer(#"{"type":"click"}"#, authorization: nil).status == 401)
        #expect(try pointer(#"{"type":"click"}"#, authorization: "Bearer wrong").status == 401)
    }

    @Test func unknownPointerTypeIs400() throws {
        let response = try pointer(#"{"type":"rightClick"}"#)
        #expect(response.status == 400)
        #expect(response.pointer == nil)
        #expect(try pointer(#"{"type":"move","dx":1}"#).status == 400)
    }

    @Test func nonFiniteOrHugeDeltaIs400() throws {
        #expect(try pointer(#"{"type":"move","dx":4001,"dy":0}"#).status == 400)
        #expect(try pointer(#"{"type":"scroll","dx":0,"dy":-4001}"#).status == 400)
        #expect(try pointer(#"{"type":"move","dx":1e999,"dy":0}"#).status == 400)
    }
}
