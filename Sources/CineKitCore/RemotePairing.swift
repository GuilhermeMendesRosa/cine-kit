import Foundation

/// The token and URL in the pairing QR code (ADR 0003).
public enum RemotePairing {
    /// 32 random bytes in base64url, without padding.
    public static func makeToken() -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    public static func url(host: String, port: Int, token: String) -> URL {
        URL(string: "http://\(host):\(port)/?token=\(token)")!
    }
}
