import Foundation

public struct RemoteResponse: Equatable, Sendable {
    public let status: Int
    public let headers: [String: String]
    public let body: Data
    /// The button to act on, for an accepted press.
    public let button: RemoteButton?
    /// The touchpad event to act on, for an accepted pointer request.
    public let pointer: RemotePointerEvent?
    /// The text to type, for an accepted text request (ADR 0016).
    public let text: String?
    /// The theme to save, for an accepted theme request (ADR 0019).
    public let theme: AppTheme?

    init(
        status: Int, headers: [String: String] = [:], body: Data = Data(),
        button: RemoteButton? = nil, pointer: RemotePointerEvent? = nil, text: String? = nil, theme: AppTheme? = nil
    ) {
        self.status = status
        self.headers = headers
        self.body = body
        self.button = button
        self.pointer = pointer
        self.text = text
        self.theme = theme
    }

    /// The bytes to send back, keeping the connection open.
    public var data: Data {
        let reasons = [200: "OK", 204: "No Content", 400: "Bad Request", 404: "Not Found"]
        var head = "HTTP/1.1 \(status) \(reasons[status] ?? "")\r\n"
        for (name, value) in headers.merging(["Content-Length": "\(body.count)", "Connection": "keep-alive"], uniquingKeysWith: { $1 }) {
            head += "\(name): \(value)\r\n"
        }
        return Data((head + "\r\n").utf8) + body
    }
}

/// Routes a request of the web remote: the API and the app's static files (ADR 0003, protocol v1, and ADRs 0012, 0016, 0019 and 0020).
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

    private struct Text: Decodable {
        let text: String
    }

    private struct ThemeBody: Decodable {
        let theme: String
    }

    private struct State: Encodable {
        let clickSound: Bool
        let theme: String
    }

    /// Longer texts are rejected: typing on the phone sends a few characters at a time.
    static let maxTextLength = 256

    /// `clickSound` is the remote's click sound for the open app (ADR 0015). `theme` is the app's theme, shared with the
    /// remote (ADR 0019). `staticFile` reads a file of the web app by its path relative to the app's folder.
    public static func response(
        for request: RemoteHTTPRequest, clickSound: Bool, theme: AppTheme, staticFile: (String) -> Data?
    ) -> RemoteResponse {
        if request.path == "/api/press", request.method == "POST" {
            return press(request)
        }
        if request.path == "/api/pointer", request.method == "POST" {
            return pointer(request)
        }
        if request.path == "/api/text", request.method == "POST" {
            return text(request)
        }
        if request.path == "/api/theme", request.method == "POST" {
            return self.theme(request)
        }
        if request.path == "/api/state", request.method == "GET" {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let body = (try? encoder.encode(State(clickSound: clickSound, theme: theme.rawValue))) ?? Data()
            return RemoteResponse(status: 200, headers: ["Content-Type": "application/json"], body: body)
        }
        guard request.method == "GET", !request.path.hasPrefix("/api/") else { return RemoteResponse(status: 404) }
        let path = request.path == "/" ? "index.html" : String(request.path.dropFirst())
        guard !path.split(separator: "/").contains(".."), let body = staticFile(path) else { return RemoteResponse(status: 404) }
        let type = contentTypes[(path as NSString).pathExtension] ?? "application/octet-stream"
        return RemoteResponse(status: 200, headers: ["Content-Type": type], body: body)
    }

    private static func press(_ request: RemoteHTTPRequest) -> RemoteResponse {
        guard let press = try? JSONDecoder().decode(Press.self, from: request.body),
              let button = RemoteButton(rawValue: press.button) else { return RemoteResponse(status: 400) }
        return RemoteResponse(status: 204, button: button)
    }

    private static func pointer(_ request: RemoteHTTPRequest) -> RemoteResponse {
        guard let event = try? JSONDecoder().decode(RemotePointerEvent.self, from: request.body) else { return RemoteResponse(status: 400) }
        return RemoteResponse(status: 204, pointer: event)
    }

    private static func text(_ request: RemoteHTTPRequest) -> RemoteResponse {
        guard let text = try? JSONDecoder().decode(Text.self, from: request.body).text,
              !text.isEmpty, text.count <= maxTextLength,
              !text.unicodeScalars.contains(where: { $0.properties.generalCategory == .control }) else {
            return RemoteResponse(status: 400)
        }
        return RemoteResponse(status: 204, text: text)
    }

    private static func theme(_ request: RemoteHTTPRequest) -> RemoteResponse {
        guard let body = try? JSONDecoder().decode(ThemeBody.self, from: request.body),
              let theme = AppTheme(rawValue: body.theme) else { return RemoteResponse(status: 400) }
        return RemoteResponse(status: 204, theme: theme)
    }
}
