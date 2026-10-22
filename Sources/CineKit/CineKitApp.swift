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
