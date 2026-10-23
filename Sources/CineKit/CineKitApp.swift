import AppKit
import CineKitCore
import SwiftUI

@main
struct CineKitApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var store = AppCatalogStore(directory: .applicationSupportDirectory.appending(path: "CineKit"))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(appDelegate.androidSetup)
                .environment(appDelegate.remoteServer)
                .environment(appDelegate.inputMode)
                .environment(appDelegate.webViewCache)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let androidSetup = AndroidSetup()
    let remoteServer = RemoteServer()
    let inputMode = InputMode()
    let webViewCache = WebViewCache()

    /// Opened by "Abrir ao iniciar o Mac", which starts the app hidden (ADR 0021).
    private var launchedAtLogin: Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchedAtLogin = launchedAtLogin
        if launchedAtLogin {
            NSApp.hide(nil)
        } else {
            NSApp.activate()
        }
        DispatchQueue.main.async {
            if !launchedAtLogin { NSApp.windows.first?.toggleFullScreen(nil) }
            // After the window exists, which it needs for mouse-moved events.
            self.inputMode.start()
        }
        remoteServer.start()
        androidSetup.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        androidSetup.runtime?.stop()
    }
}
