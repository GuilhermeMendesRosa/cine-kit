import AppKit
import SwiftUI

@main
struct CineKitApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
        DispatchQueue.main.async {
            NSApp.windows.first?.toggleFullScreen(nil)
        }
    }
}
