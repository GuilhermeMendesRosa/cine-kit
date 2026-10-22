import Foundation

public struct RemoteResponse: Equatable, Sendable {
    public let status: Int
    public let headers: [String: String]
    public let body: Data
    /// The button to act on, for an accepted press.
    public let button: RemoteButton?
    /// The touchpad event to act on, for an accepted pointer request.
    public let pointer: RemotePointerEvent?

    init(status: Int, headers: [String: String] = [:], body: Data = Data(), button: RemoteButton? = nil, pointer: RemotePointerEvent? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
        self.button = button
        self.pointer = pointer
    }

    /// The bytes to send back, keeping the connection open.
    public var data: Data {
        let reasons = [200: "OK", 204: "No Content", 400: "Bad Request", 401: "Unauthorized", 404: "Not Found"]
        var head = "HTTP/1.1 \(status) \(reasons[status] ?? "")\r\n"
        for (name, value) in headers.merging(["Content-Length": "\(body.count)", "Connection": "keep-alive"], uniquingKeysWith: { $1 }) {
            head += "\(name): \(value)\r\n"
        }
        return Data((head + "\r\n").utf8) + body
    }
}

/// Routes a request of the web remote: the API and the app's static files (ADR 0003, protocol v1, and ADR 0012).
public enum RemoteRoute {
    private static let contentTypes = [
        "html": "text/html; charset=utf-8",
        "js": "text/javascript; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "png": "image/png",
        "webmanifest": "application/manifest+json",
        "svg": "image/svg+xml",
    ]

    private struct Press: Decodable {
        let button: String
    }

    /// `staticFile` reads a file of the web app by its path relative to the app's folder.
    public static func response(for request: RemoteHTTPRequest, token: String, staticFile: (String) -> Data?) -> RemoteResponse {
        if request.path == "/api/press", request.method == "POST" {
            return press(request, token: token)
        }
        if request.path == "/api/pointer", request.method == "POST" {
            return pointer(request, token: token)
        }
        guard request.method == "GET", !request.path.hasPrefix("/api/") else { return RemoteResponse(status: 404) }
        let path = request.path == "/" ? "index.html" : String(request.path.dropFirst())
        guard !path.split(separator: "/").contains(".."), let body = staticFile(path) else { return RemoteResponse(status: 404) }
        let type = contentTypes[(path as NSString).pathExtension] ?? "application/octet-stream"
        return RemoteResponse(status: 200, headers: ["Content-Type": type], body: body)
    }

    private static func press(_ request: RemoteHTTPRequest, token: String) -> RemoteResponse {
        guard authorized(request, token: token) else { return RemoteResponse(status: 401) }
        guard let press = try? JSONDecoder().decode(Press.self, from: request.body),
              let button = RemoteButton(rawValue: press.button) else { return RemoteResponse(status: 400) }
        return RemoteResponse(status: 204, button: button)
    }

    private static func pointer(_ request: RemoteHTTPRequest, token: String) -> RemoteResponse {
        guard authorized(request, token: token) else { return RemoteResponse(status: 401) }
        guard let event = try? JSONDecoder().decode(RemotePointerEvent.self, from: request.body) else { return RemoteResponse(status: 400) }
        return RemoteResponse(status: 204, pointer: event)
    }

    private static func authorized(_ request: RemoteHTTPRequest, token: String) -> Bool {
        guard let authorization = request.headers["authorization"] else { return false }
        return constantTimeEquals(authorization, "Bearer \(token)")
    }

    private static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let a = Array(a.utf8), b = Array(b.utf8)
        guard a.count == b.count else { return false }
        return zip(a, b).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
