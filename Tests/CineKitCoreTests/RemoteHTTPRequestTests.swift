import Foundation
import Testing
@testable import CineKitCore

struct RemoteHTTPRequestTests {
    @Test func parsesGetWithQuery() throws {
        let request = try #require(RemoteHTTPRequest.parse(Data("GET /index.html?token=abc&x=1 HTTP/1.1\r\nHost: mac.local\r\n\r\n".utf8)))
        #expect(request.method == "GET")
        #expect(request.path == "/index.html")
        #expect(request.query == ["token": "abc", "x": "1"])
        #expect(request.body.isEmpty)
    }

    @Test func parsesPostBodyByContentLength() throws {
        let raw = "POST /api/press HTTP/1.1\r\nContent-Length: 13\r\n\r\n{\"button\":1}X"
        let request = try #require(RemoteHTTPRequest.parse(Data(raw.utf8)))
        #expect(request.method == "POST")
        #expect(request.body == Data("{\"button\":1}X".utf8))
    }

    @Test func incompleteReturnsNil() {
        #expect(RemoteHTTPRequest.parse(Data("GET / HTTP/1.1\r\nHost: mac".utf8)) == nil)
        #expect(RemoteHTTPRequest.parse(Data("POST /api/press HTTP/1.1\r\nContent-Length: 20\r\n\r\n{\"button\"".utf8)) == nil)
    }

    @Test func lowercasesHeaderNames() throws {
        let request = try #require(RemoteHTTPRequest.parse(Data("GET / HTTP/1.1\r\nAuthorization: Bearer abc\r\n\r\n".utf8)))
        #expect(request.headers["authorization"] == "Bearer abc")
    }
}
