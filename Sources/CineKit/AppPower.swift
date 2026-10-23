import AppKit

/// The remote's power button: hides the app when it is on screen, else brings it to the front in full screen (ADR 0021).
@MainActor
enum AppPower {
    private static var mainWindow: NSWindow? {
        NSApp.windows.first { $0.canBecomeMain }
    }

    /// On screen, whichever app is active; a full screen window in another Space is not.
    static var isOn: Bool {
        !NSApp.isHidden && mainWindow?.occlusionState.contains(.visible) == true
    }

    /// `goHome` runs before hiding, so the open service pauses (ADR 0014).
    static func toggle(goHome: () -> Void) {
        if isOn {
            goHome()
            // On the next run loop cycle, after the posted keys reach the window.
            DispatchQueue.main.async { NSApp.hide(nil) }
        } else {
            turnOn()
        }
    }

    private static func turnOn() {
        NSApp.unhide(nil)
        mainWindow?.makeKeyAndOrderFront(nil)
        // From the background, `NSApp.activate()` is only a request that macOS 14+ turns down while another app
        // is in front; opening the app through Launch Services activates it like a click on the Dock.
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration)
        Task {
            // Full screen is ignored while the window is still coming back on screen, so retry until it takes.
            for _ in 0..<12 {
                try? await Task.sleep(for: .milliseconds(250))
                guard let window = mainWindow else { return }
                if window.styleMask.contains(.fullScreen) { return }
                if NSApp.isActive {
                    window.toggleFullScreen(nil)
                    // Long enough for the animation, after which the style mask says whether it took.
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
    }
}
