import Foundation

public struct ValidatedApp: Equatable, Sendable {
    public let name: String
    public let url: URL
}

public enum AppDraftError: Error, Equatable, Sendable {
    case emptyName, emptyLink, unsupportedScheme, missingHost
}

public struct AppDraft: Sendable {
    public var name: String
    public var link: String

    public init(name: String, link: String) {
        self.name = name
        self.link = link
    }

    public func validate() -> Result<ValidatedApp, AppDraftError> {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .failure(.emptyName) }
        let link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty else { return .failure(.emptyLink) }
        // "host:8080" is a port, not a scheme.
        let hasScheme = link.firstMatch(of: /^[a-zA-Z][a-zA-Z0-9+.\-]*:(?!\d)/) != nil
        let withScheme = hasScheme ? link : "https://" + link
        guard let url = URL(string: withScheme), let scheme = url.scheme?.lowercased() else {
            return .failure(.missingHost)
        }
        guard scheme == "http" || scheme == "https" else { return .failure(.unsupportedScheme) }
        guard let host = url.host(), !host.isEmpty else { return .failure(.missingHost) }
        return .success(ValidatedApp(name: name, url: url))
    }
}
