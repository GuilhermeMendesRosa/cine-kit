import Foundation

/// The fixed URL of the web remote, shown in the QR code (ADR 0020).
public enum RemotePairing {
    public static func url(host: String, port: Int) -> URL {
        URL(string: "http://\(host):\(port)/")!
    }
}
