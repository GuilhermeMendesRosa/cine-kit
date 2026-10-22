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
                .environment(appDelegate.androidRuntime)
                .environment(appDelegate.remoteServer)
                .environment(appDelegate.inputMode)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Nil without the Android SDK: the Android UI stays hidden (ADR 0004).
    let androidRuntime = AndroidSDK.default.isAvailable ? AndroidRuntime(sdk: .default, runner: ProcessCommandRunner()) : nil
    let remoteServer = RemoteServer()
    let inputMode = InputMode()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
        DispatchQueue.main.async {
            NSApp.windows.first?.toggleFullScreen(nil)
            // After the window exists, which it needs for mouse-moved events.
            self.inputMode.start()
        }
        remoteServer.start()
        if let androidRuntime {
            // A failure here is retried when an Android app is opened.
            let resolution = UserDefaults.standard.string(forKey: "androidResolution").flatMap(AndroidRuntime.Resolution.init) ?? .hd1080
            Task { try? await androidRuntime.start(resolution: resolution) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        androidRuntime?.stop()
    }
}
