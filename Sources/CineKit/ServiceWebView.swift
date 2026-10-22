import CineKitCore
import SwiftUI
import WebKit

struct ServiceWebView: NSViewRepresentable {
    static let safariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"

    let url: URL
    let onExit: () -> Void
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
        webView.onExit = onExit
        webView.handlesBack = profile.handlesBack
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
    private static let leftBracketKeyCode: UInt16 = 33
    private static let escapeKeyCode: UInt16 = 53
    private static let deleteKeyCode: UInt16 = 51

    var onExit: () -> Void = {}
    var handlesBack = false
    private var escapeMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        if window != nil, escapeMonitor == nil {
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
                guard let self, event.keyCode == Self.escapeKeyCode else { return event }
                handleEscape(event)
                return nil
            }
        } else if window == nil, let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
    }

    /// Esc is Back on release; holding it (first auto-repeat) goes home from anywhere (ADR 0012).
    private func handleEscape(_ event: NSEvent) {
        if event.type == .keyDown {
            if event.isARepeat { onExit() }
            return
        }
        switch WebBack.action(isFullscreen: fullscreenState == .inFullscreen, handlesBack: handlesBack, canGoBack: canGoBack) {
        case .exitFullscreen:
            evaluateJavaScript("document.exitFullscreen()")
        case .sendBackspace:
            for type in [NSEvent.EventType.keyDown, .keyUp] {
                guard let backspace = NSEvent.keyEvent(
                    with: type, location: .zero, modifierFlags: [], timestamp: event.timestamp,
                    windowNumber: event.windowNumber, context: nil, characters: "\u{7F}",
                    charactersIgnoringModifiers: "\u{7F}", isARepeat: false, keyCode: Self.deleteKeyCode
                ) else { continue }
                type == .keyDown ? keyDown(with: backspace) : keyUp(with: backspace)
            }
        case .goBack:
            goBack()
        case .exit:
            onExit()
        }
    }

    // ⌘[ is Back, as in Safari; with no history it leaves the service (ADR 0003).
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command), event.keyCode == Self.leftBracketKeyCode else {
            return super.performKeyEquivalent(with: event)
        }
        if canGoBack { goBack() } else { onExit() }
        return true
    }
}
