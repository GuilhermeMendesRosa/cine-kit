import Foundation

/// The bits of an HTTP/1.1 request the remote server needs (ADR 0003).
public struct RemoteHTTPRequest: Equatable, Sendable {
    public let method: String
    public let path: String
    public let query: [String: String]
    /// Keys are lowercased.
    public let headers: [String: String]
    public let body: Data

    /// Nil until the head and the whole Content-Length body have arrived, or when the request line is malformed.
    public static func parse(_ data: Data) -> RemoteHTTPRequest? {
        guard let headEnd = data.firstRange(of: Data("\r\n\r\n".utf8)),
              let head = String(data: data[..<headEnd.lowerBound], encoding: .utf8) else { return nil }
        let lines = head.components(separatedBy: "\r\n")
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count == 3, let components = URLComponents(string: String(requestLine[1])) else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[line[..<colon].lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }

        let length = headers["content-length"].flatMap(Int.init) ?? 0
        let bodyStart = headEnd.upperBound
        guard data.distance(from: bodyStart, to: data.endIndex) >= length else { return nil }

        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            query[item.name] = item.value ?? ""
        }
        return RemoteHTTPRequest(
            method: String(requestLine[0]),
            path: components.path,
            query: query,
            headers: headers,
            body: Data(data[bodyStart..<data.index(bodyStart, offsetBy: length)])
        )
    }
}
