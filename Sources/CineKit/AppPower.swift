import AppKit

/// The remote's power button: hides the app when it is on, else brings it to the front in full screen, making a new
/// window if it was closed (ADR 0021).
@MainActor
enum AppPower {
    private static var mainWindow: NSWindow? {
        NSApp.windows.first { $0.canBecomeMain }
    }

    /// Not hidden and in full screen, however it got there; a full screen window in another Space counts too.
    static var isOn: Bool {
        !NSApp.isHidden && mainWindow?.styleMask.contains(.fullScreen) == true
    }

    /// `goHome` runs before hiding, so the open service pauses (ADR 0014).
    static func toggle(goHome: () -> Void) {
        if isOn { turnOff(goHome: goHome) } else { turnOn() }
    }

    /// Does nothing when the app is already off, so the sleep timer never turns it back on (ADR 0024).
    static func turnOff(goHome: () -> Void) {
        guard isOn else { return }
        goHome()
        // On the next run loop cycle, after the posted keys reach the window.
        DispatchQueue.main.async { finishTurningOff() }
    }

    /// Leaves full screen before hiding, so no empty Space is left behind.
    private static func finishTurningOff() {
        guard let window = mainWindow, window.styleMask.contains(.fullScreen) else {
            NSApp.hide(nil)
            return
        }
        let exited = NotificationCenter.default.notifications(named: NSWindow.didExitFullScreenNotification, object: window)
        window.toggleFullScreen(nil)
        Task {
            for await _ in exited { break }
            NSApp.hide(nil)
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
                // A closed window comes back from the reopen, a moment after the app activates.
                guard let window = mainWindow else { continue }
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
