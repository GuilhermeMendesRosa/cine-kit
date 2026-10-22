import AppKit
import CineKitCore
import SwiftUI

struct RootView: View {
    private static let escapeKeyCode: UInt16 = 53

    @Environment(AppCatalogStore.self) private var store
    @Environment(RemoteServer.self) private var remoteServer
    @State private var openApp: StreamingApp?
    @State private var isShowingSettings = false
    @State private var loadError: String?
    @State private var shelfFocus = ShelfFocusState(target: .card(0), lastCard: 0)
    @State private var escapeMonitor: Any?

    var body: some View {
        Group {
            if let openApp {
                if openApp.androidPackage != nil {
                    AndroidScreen(app: openApp) { self.openApp = nil }
                } else {
                    ServiceScreen(app: openApp) { self.openApp = nil }
                }
            } else if isShowingSettings {
                SettingsView()
            } else {
                HomeView(apps: store.apps, focus: $shelfFocus, onOpen: { openApp = $0 }, onOpenSettings: { isShowingSettings = true })
            }
        }
        .alert("Não foi possível carregar os apps", isPresented: .constant(loadError != nil)) {
            Button("OK") { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
        .onAppear {
            do {
                try store.load()
            } catch {
                loadError = error.localizedDescription
            }
            // Local monitors run before the event reaches the web view, so Esc always goes home.
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == Self.escapeKeyCode else { return event }
                if openApp != nil {
                    // Android apps take Esc as the remote's Back button.
                    if openApp?.androidPackage != nil { return event }
                    openApp = nil
                    return nil
                }
                // With a sheet, dialog or alert open, Esc belongs to it.
                if isShowingSettings, NSApp.keyWindow?.isSheet != true {
                    closeSettings()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        }
        .onChange(of: openApp, initial: true) { _, app in
            remoteServer.screen = switch app {
            case nil: .other
            case let app? where app.androidPackage != nil: .android
            default: .web
            }
        }
    }

    private func closeSettings() {
        isShowingSettings = false
        // Apps may have been removed while in settings.
        shelfFocus.lastCard = max(0, min(shelfFocus.lastCard, store.apps.count - 1))
    }
}
