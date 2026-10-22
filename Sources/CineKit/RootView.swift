import AppKit
import CineKitCore
import SwiftUI

struct RootView: View {
    private static let escapeKeyCode: UInt16 = 53

    @State private var openApp: StreamingApp?
    @State private var shelfFocus = ShelfFocusState(target: .card(0), lastCard: 0)
    @State private var escapeMonitor: Any?

    var body: some View {
        Group {
            if let openApp {
                ServiceScreen(app: openApp)
            } else {
                HomeView(apps: DefaultApps.all, focus: $shelfFocus) { openApp = $0 }
            }
        }
        .onAppear {
            // Local monitors run before the event reaches the web view, so Esc always goes home.
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == Self.escapeKeyCode, openApp != nil else { return event }
                openApp = nil
                return nil
            }
        }
        .onDisappear {
            if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        }
    }
}
