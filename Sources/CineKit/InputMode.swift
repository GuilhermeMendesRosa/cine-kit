import AppKit
import Observation

/// Whether the user is on the keys or the pointer, so hover moves focus only while pointing (ADR 0012).
@MainActor
@Observable
final class InputMode {
    enum Kind {
        case keys, pointer
    }

    private(set) var kind = Kind.keys
    @ObservationIgnored private var monitor: Any?

    func start() {
        NSApp.windows.first?.acceptsMouseMovedEvents = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .mouseMoved, .leftMouseDown, .leftMouseDragged, .scrollWheel]) { [weak self] event in
            if event.type == .keyDown {
                self?.kind = .keys
                NSCursor.setHiddenUntilMouseMoves(true)
            } else {
                self?.kind = .pointer
            }
            return event
        }
    }
}
