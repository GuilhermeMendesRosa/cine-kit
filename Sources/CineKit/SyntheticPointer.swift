import AppKit
import CineKitCore

/// Moves the real Mac pointer and posts mouse events to the app, like the remote's keys (ADR 0012). Needs no
/// Accessibility permission. The position is always read back from the system, so the physical mouse and the
/// remote's touchpad continue from the same point.
@MainActor
enum SyntheticPointer {
    static func perform(_ event: RemotePointerEvent) {
        switch event {
        case .move(let dx, let dy):
            let start = NSEvent.mouseLocation
            // The phone's y grows downwards; the screen's grows upwards.
            move(to: NSPoint(x: start.x + dx, y: start.y - dy))
        case .click:
            post(.leftMouseDown, at: NSEvent.mouseLocation)
            post(.leftMouseUp, at: NSEvent.mouseLocation)
        case .scroll(let dx, let dy):
            scroll(dx: dx, dy: dy)
        }
    }

    private static func move(to point: NSPoint) {
        guard let frame = (NSApp.windows.first?.screen ?? NSScreen.main)?.frame else { return }
        let clamped = NSPoint(x: min(max(point.x, frame.minX), frame.maxX - 1), y: min(max(point.y, frame.minY), frame.maxY - 1))
        CGWarpMouseCursorPosition(cgPoint(clamped))
        // A warp suppresses the physical mouse for 250 ms unless it is re-associated right away.
        CGAssociateMouseAndMouseCursorPosition(1)
        NSCursor.setHiddenUntilMouseMoves(false)
        post(.mouseMoved, at: clamped)
    }

    private static func post(_ type: NSEvent.EventType, at point: NSPoint) {
        guard let window = window(at: point),
              let event = NSEvent.mouseEvent(
                  with: type,
                  location: window.convertPoint(fromScreen: point),
                  modifierFlags: [],
                  timestamp: ProcessInfo.processInfo.systemUptime,
                  windowNumber: window.windowNumber,
                  context: nil,
                  eventNumber: 0,
                  clickCount: type == .mouseMoved ? 0 : 1,
                  pressure: type == .leftMouseDown ? 1 : 0
              ) else { return }
        NSApp.postEvent(event, atStart: false)
    }

    /// Pixel deltas that the content follows, as with natural scrolling.
    private static func scroll(dx: Double, dy: Double) {
        let point = NSEvent.mouseLocation
        guard let window = window(at: point),
              let cgEvent = CGEvent(
                  scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(dy), wheel2: Int32(dx), wheel3: 0
              ) else { return }
        // An NSEvent made from a CGEvent has no window: its location in the window is the CGEvent's location
        // converted as if it were on the screen, and only sending it to the window directly reaches the view.
        cgEvent.location = cgPoint(window.convertPoint(fromScreen: point))
        guard let event = NSEvent(cgEvent: cgEvent) else { return }
        window.sendEvent(event)
    }

    private static func window(at point: NSPoint) -> NSWindow? {
        NSApp.window(withWindowNumber: NSWindow.windowNumber(at: point, belowWindowWithWindowNumber: 0))
    }

    /// Core Graphics puts the origin at the top left of the main screen.
    private static func cgPoint(_ point: NSPoint) -> CGPoint {
        CGPoint(x: point.x, y: (NSScreen.screens.first?.frame.height ?? 0) - point.y)
    }
}
