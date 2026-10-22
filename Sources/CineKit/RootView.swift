import AppKit
import CineKitCore
import SwiftUI
import WebKit

struct RootView: View {
    private static let escapeKeyCode: UInt16 = 53

    @Environment(AppCatalogStore.self) private var store
    @Environment(WebViewCache.self) private var webViewCache
    @Environment(RemoteServer.self) private var remoteServer
    @Environment(AndroidSetup.self) private var androidSetup
    @State private var openApp: StreamingApp?
    @State private var isShowingSettings = false
    @State private var loadError: String?
    @State private var shelfFocus = ShelfFocusState(target: .card(0), lastCard: 0)
    @State private var escapeMonitor: Any?
    @AppStorage("appTheme") private var theme = AppTheme.dark
    @AppStorage("askedAndroidInstall") private var askedAndroidInstall = false

    var body: some View {
        Group {
            if let openApp {
                Group {
                    if openApp.androidPackage != nil {
                        AndroidScreen(app: openApp) { self.openApp = nil }
                    } else {
                        ServiceScreen(app: openApp) { self.openApp = nil }
                    }
                }
                // Media screens stay dark whatever the theme (ADR 0013).
                .environment(\.colorScheme, .dark)
            } else if isShowingSettings {
                SettingsView(onClose: closeSettings)
            } else {
                HomeView(apps: store.apps, focus: $shelfFocus, onOpen: { openApp = $0 }, onOpenSettings: { isShowingSettings = true })
            }
        }
        // Here and not in the App, so the runtime reaches the screens as soon as the install creates it.
        .environment(androidSetup.runtime)
        .onChange(of: store.apps) { _, apps in webViewCache.discardStale(apps) }
        // Asked once, on the first launch without the SDK (ADR 0018); Settings keeps the install button.
        .alert("Instalar o suporte a apps Android?", isPresented: .constant(!askedAndroidInstall && androidSetup.runtime == nil)) {
            Button("Instalar") {
                askedAndroidInstall = true
                androidSetup.install()
                isShowingSettings = true
            }
            .keyboardShortcut(.defaultAction)
            Button("Agora não", role: .cancel) { askedAndroidInstall = true }
        } message: {
            Text(AndroidSetup.installMessage)
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
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == Self.escapeKeyCode else { return event }
                if openApp != nil {
                    // Android apps and web pages take Esc as Back (ADR 0012); a failed web page has no web view left.
                    if openApp?.androidPackage != nil || NSApp.keyWindow?.firstResponder is WKWebView { return event }
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
        // The app's appearance also reaches sheets, alerts and panels.
        .onChange(of: theme, initial: true) { NSApp.appearance = $1.appearance }
        // The home and the settings always click.
        .onChange(of: openApp, initial: true) { remoteServer.clickSound = $1?.remoteClickSound ?? true }
    }

    private func closeSettings() {
        isShowingSettings = false
        // Apps may have been removed while in settings.
        shelfFocus.lastCard = max(0, min(shelfFocus.lastCard, store.apps.count - 1))
    }
}
