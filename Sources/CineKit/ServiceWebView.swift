import CineKitCore
import SwiftUI
import WebKit

struct ServiceWebView: NSViewRepresentable {
    static let safariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"

    let url: URL
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFailure: onFailure)
    }

    func makeNSView(context: Context) -> WKWebView {
        let profile = WebProfile.for(url)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        if profile.usesSpatialNavigation {
            let scriptURL = Bundle.module.url(forResource: "spatial-navigation", withExtension: "js")!
            let script = try! String(contentsOf: scriptURL, encoding: .utf8)
            configuration.userContentController.addUserScript(
                WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        let webView = FocusingWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = profile.userAgent ?? Self.safariUserAgent
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: profile.url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let onFailure: () -> Void

        init(onFailure: @escaping () -> Void) {
            self.onFailure = onFailure
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        // Redirects and superseded loads arrive as "cancelled"; they are not failures.
        private func report(_ error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            onFailure()
        }
    }
}

// The home leaves the screen and keyboard focus does not reach the web view on its own.
private final class FocusingWebView: WKWebView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}
