import Foundation

/// How a web service is loaded: YouTube gets its TV UI, the rest the desktop site with spatial navigation (ADR 0010).
public struct WebProfile: Equatable, Sendable {
    public static let tvUserAgent = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/538.1 (KHTML, like Gecko) Version/6.0 TV Safari/538.1"

    public var url: URL
    public var userAgent: String?
    public var usesSpatialNavigation: Bool
    /// The page handles Back itself (YouTube TV takes Backspace).
    public var handlesBack: Bool

    public static func `for`(_ url: URL) -> WebProfile {
        if ["youtube.com", "www.youtube.com"].contains(url.host()) {
            return WebProfile(url: URL(string: "https://www.youtube.com/tv")!, userAgent: tvUserAgent, usesSpatialNavigation: false, handlesBack: true)
        }
        return WebProfile(url: url, userAgent: nil, usesSpatialNavigation: true, handlesBack: false)
    }
}
