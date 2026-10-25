import Foundation

/// How a web service is loaded: YouTube gets its TV UI, the rest the desktop site with spatial navigation (ADR 0010), and Netflix also gets FlixBypass (ADR 0023).
public struct WebProfile: Equatable, Sendable {
    public static let tvUserAgent = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/538.1 (KHTML, like Gecko) Version/6.0 TV Safari/538.1"

    public var url: URL
    public var userAgent: String?
    public var usesSpatialNavigation: Bool
    /// The page handles Back itself (YouTube TV takes Backspace).
    public var handlesBack: Bool
    /// The page gets the FlixBypass scripts, which skip Netflix's household check.
    public var bypassesNetflixHousehold: Bool

    public static func `for`(_ url: URL) -> WebProfile {
        if ["youtube.com", "www.youtube.com"].contains(url.host()) {
            return WebProfile(url: URL(string: "https://www.youtube.com/tv")!, userAgent: tvUserAgent, usesSpatialNavigation: false, handlesBack: true, bypassesNetflixHousehold: false)
        }
        return WebProfile(url: url, userAgent: nil, usesSpatialNavigation: true, handlesBack: false, bypassesNetflixHousehold: url.host().map { $0 == "netflix.com" || $0.hasSuffix(".netflix.com") } ?? false)
    }
}
