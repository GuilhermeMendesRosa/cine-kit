import Foundation
import Testing
@testable import CineKitCore

struct RemoteRouteTests {
    private let files = [
        "index.html": Data("<html>".utf8),
        "assets/app.js": Data("js".utf8),
    ]

    private func respond(
        _ raw: String, clickSound: Bool = true, theme: AppTheme = .dark, power: Bool = false, sleep: Int? = nil
    ) throws -> RemoteResponse {
        let request = try #require(RemoteHTTPRequest.parse(Data(raw.utf8)))
        return RemoteRoute.response(for: request, clickSound: clickSound, theme: theme, power: power, sleep: sleep) { files[$0] }
    }

    private func press(_ body: String) throws -> RemoteResponse {
        try respond("POST /api/press HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    private func pointer(_ body: String) throws -> RemoteResponse {
        try respond("POST /api/pointer HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    private func text(_ body: String) throws -> RemoteResponse {
        try respond("POST /api/text HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    private func themeRequest(_ body: String) throws -> RemoteResponse {
        try respond("POST /api/theme HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    private func sleepRequest(_ body: String) throws -> RemoteResponse {
        try respond("POST /api/sleep HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)")
    }

    @Test func rootServesIndex() throws {
        let response = try respond("GET / HTTP/1.1\r\n\r\n")
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

    @Test func pressWithoutAuthorizationIsAccepted() throws {
        let response = try press(#"{"button":"ok"}"#)
        #expect(response.status == 204)
        #expect(response.button == .ok)
    }

    @Test func unknownButtonIs400() throws {
        let response = try press(#"{"button":"rewind"}"#)
        #expect(response.status == 400)
        #expect(response.button == nil)
    }

    @Test func pressPowerIsAccepted() throws {
        let response = try press(#"{"button":"power"}"#)
        #expect(response.status == 204)
        #expect(response.button == .power)
    }

    @Test func validPressReturns204AndButton() throws {
        let response = try press(#"{"button":"playPause"}"#)
        #expect(response.status == 204)
        #expect(response.button == .playPause)
    }

    @Test func rejectsPathTraversal() throws {
        let request = try #require(RemoteHTTPRequest.parse(Data("GET /../secret.txt HTTP/1.1\r\n\r\n".utf8)))
        var asked = false
        let response = RemoteRoute.response(for: request, clickSound: true, theme: .dark, power: false, sleep: nil) { _ in
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

    @Test func stateReturnsClickSound() throws {
        let response = try respond("GET /api/state HTTP/1.1\r\n\r\n", clickSound: false)
        #expect(response.status == 200)
        #expect(response.headers["Content-Type"] == "application/json")
        #expect(response.body == Data(#"{"clickSound":false,"power":false,"sleep":null,"theme":"dark"}"#.utf8))
    }

    @Test func stateReturnsTheme() throws {
        let response = try respond("GET /api/state HTTP/1.1\r\n\r\n", theme: .light)
        #expect(String(decoding: response.body, as: UTF8.self).contains(#""theme":"light""#))
    }

    @Test func stateReturnsPower() throws {
        let response = try respond("GET /api/state HTTP/1.1\r\n\r\n", power: true)
        #expect(String(decoding: response.body, as: UTF8.self).contains(#""power":true"#))
    }

    @Test func themeReturns204WithTheTheme() throws {
        let response = try themeRequest(#"{"theme":"light"}"#)
        #expect(response.status == 204)
        #expect(response.theme == .light)
    }

    @Test func themeWithUnknownValueIs400() throws {
        let response = try themeRequest(#"{"theme":"system"}"#)
        #expect(response.status == 400)
        #expect(response.theme == nil)
        #expect(try themeRequest("dark").status == 400)
    }

    @Test func sleepWithValidMinutesIsAccepted() throws {
        let response = try sleepRequest(#"{"minutes":30}"#)
        #expect(response.status == 204)
        #expect(response.sleepMinutes == 30)
    }

    @Test func sleepZeroCancels() throws {
        let response = try sleepRequest(#"{"minutes":0}"#)
        #expect(response.status == 204)
        #expect(response.sleepMinutes == 0)
    }

    @Test func sleepWithInvalidMinutesIs400() throws {
        for body in [#"{"minutes":20}"#, #"{"minutes":-5}"#, #"{"minutes":"30"}"#, "{}"] {
            let response = try sleepRequest(body)
            #expect(response.status == 400)
            #expect(response.sleepMinutes == nil)
        }
    }

    @Test func getSleepIs404() throws {
        #expect(try respond("GET /api/sleep HTTP/1.1\r\n\r\n").status == 404)
    }

    @Test func stateIncludesSleep() throws {
        let running = try respond("GET /api/state HTTP/1.1\r\n\r\n", sleep: 1740)
        #expect(String(decoding: running.body, as: UTF8.self).contains(#""sleep":1740"#))
        let idle = try respond("GET /api/state HTTP/1.1\r\n\r\n")
        #expect(String(decoding: idle.body, as: UTF8.self).contains(#""sleep":null"#))
    }

    @Test func stateWithoutAuthorizationIsServed() throws {
        let response = try respond("GET /api/state HTTP/1.1\r\n\r\n")
        #expect(response.status == 200)
        #expect(response.body == Data(#"{"clickSound":true,"power":false,"sleep":null,"theme":"dark"}"#.utf8))
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

    @Test func deletePressReturns204() throws {
        #expect(try press(#"{"button":"delete"}"#).button == .delete)
    }

    @Test func textReturns204AndText() throws {
        let response = try text(#"{"text":"ação 👍"}"#)
        #expect(response.status == 204)
        #expect(response.text == "ação 👍")
    }

    @Test func emptyLongOrControlTextIs400() throws {
        #expect(try text(#"{"text":""}"#).status == 400)
        #expect(try text(#"{"text":"\#(String(repeating: "a", count: 257))"}"#).status == 400)
        #expect(try text(#"{"text":"a\nb"}"#).status == 400)
        #expect(try text(#"{"text":"\u001b"}"#).status == 400)
        #expect(try text(#"{"txt":"a"}"#).text == nil)
    }
}
