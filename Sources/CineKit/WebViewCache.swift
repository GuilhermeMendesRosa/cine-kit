import CineKitCore
import Observation
import WebKit

/// Keeps the most recent web services' pages alive, so leaving one and coming back resumes where it was (ADR 0014).
@MainActor
@Observable
final class WebViewCache {
    static let capacity = 3

    @ObservationIgnored private var recent = RecentWebApps(capacity: capacity)
    @ObservationIgnored private var entries: [StreamingApp.ID: (url: URL, webView: WKWebView)] = [:]

    /// The cached page for `app`, or a new one from `make` when there is none for its current URL.
    func webView(for app: StreamingApp, make: () -> WKWebView) -> WKWebView {
        let webView: WKWebView
        if let entry = entries[app.id], entry.url == app.url {
            webView = entry.webView
        } else {
            webView = make()
            entries[app.id] = (app.url, webView)
        }
        for id in recent.touch(app.id) { entries[id] = nil }
        return webView
    }

    func discard(_ id: StreamingApp.ID) {
        entries[id] = nil
        recent.remove(id)
    }

    /// Drops the pages of apps that were removed or now point at another URL.
    func discardStale(_ apps: [StreamingApp]) {
        RecentWebApps.stale(cached: entries.mapValues(\.url), current: apps).forEach(discard)
    }
}
