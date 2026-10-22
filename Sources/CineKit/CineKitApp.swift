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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
        DispatchQueue.main.async {
            NSApp.windows.first?.toggleFullScreen(nil)
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
