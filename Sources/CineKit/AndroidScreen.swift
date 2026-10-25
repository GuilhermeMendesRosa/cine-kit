import AppKit
import CineKitCore
import SwiftUI

/// Shows only the Android app: the video starts once the app is in the foreground, so the launcher never shows (ADR 0004, 0009).
struct AndroidScreen: View {
    private enum Phase {
        case opening, playing, failed
    }

    private static let escapeKeyCode: UInt16 = 53
    private static let backKeycode: Int32 = 4

    let app: StreamingApp
    let onExit: () -> Void

    @Environment(AndroidRuntime.self) private var runtime: AndroidRuntime?
    @State private var phase = Phase.opening
    @State private var frames: EmulatorFrameSource?
    @State private var client: ScrcpyClient?
    @State private var keyMonitor: Any?
    @AppStorage("androidResolution") private var resolution = AndroidRuntime.Resolution.hd1080
    @AppStorage("androidCores") private var cores = AndroidRuntime.Hardware.defaultCores
    @AppStorage("androidMemory") private var memoryMB = AndroidRuntime.Hardware.defaultMemoryMB

    var body: some View {
        Group {
            switch phase {
            case .opening:
                VStack(spacing: 24) {
                    ProgressView()
                        .controlSize(.extraLarge)
                    Text("Abrindo \(app.name)…")
                        .font(.largeTitle.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
            case .playing:
                if let frames {
                    EmulatorFrameView(source: frames) { client?.send($0) }
                        .ignoresSafeArea()
                }
            case .failed:
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 96))
                    Text("Não foi possível abrir \(app.name).")
                        .font(.largeTitle.bold())
                    Text("Esc para voltar")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
            }
        }
        .onAppear(perform: installKeyMonitor)
        .task { await open() }
        .onDisappear(perform: close)
    }

    private func open() async {
        guard let runtime, let package = app.androidPackage else {
            phase = .failed
            return
        }
        do {
            let deadline = ContinuousClock.now + .seconds(90)
            try await runtime.ensureRunning(AndroidRuntime.Hardware(resolution: resolution, cores: cores, memoryMB: memoryMB))
            try await runtime.waitUntilBooted()
            try await runtime.launch(package: package)
            while try await runtime.foregroundPackage() != package {
                guard ContinuousClock.now < deadline else { throw AndroidRuntimeError.bootTimeout }
                try await Task.sleep(for: .milliseconds(250))
            }
            try Task.checkCancellation()
            let client = ScrcpyClient(sdk: .default, runner: ProcessCommandRunner())
            self.client = client
            try await client.start()
            frames = try EmulatorFrameSource()
            try Task.checkCancellation()
            phase = .playing
            // Back on the app's root screen closes it: return home without streaming the launcher.
            while true {
                try await Task.sleep(for: .seconds(1))
                if let foreground = try await runtime.foregroundPackage(), foreground != package {
                    client.stop()
                    onExit()
                    return
                }
            }
        } catch {
            // Also covers leaving the screen while it was opening.
            client?.stop()
            phase = .failed
        }
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            if event.keyCode == Self.escapeKeyCode {
                handleEscape(event)
                return nil
            }
            guard phase == .playing, let client else { return event }
            let modifiers: Set<AndroidKeyMap.Modifier> = event.modifierFlags.contains(.command) ? [.command] : []
            guard let action = AndroidKeyMap.action(keyCode: event.keyCode, characters: event.characters, modifiers: modifiers) else {
                return event
            }
            let isDown = event.type == .keyDown
            switch action {
            case .key(let keycode):
                client.send(.injectKeycode(action: isDown ? .down : .up, keycode: keycode, repeat: event.isARepeat ? 1 : 0))
            case .text(let text):
                if isDown { client.send(.injectText(text)) }
            }
            return nil
        }
    }

    /// Esc is the remote's Back; holding it (first auto-repeat) goes home from anywhere.
    private func handleEscape(_ event: NSEvent) {
        guard phase == .playing, let client else {
            if event.type == .keyDown { onExit() }
            return
        }
        if event.type == .keyDown {
            if event.isARepeat { onExit() }
        } else {
            client.send(.injectKeycode(action: .down, keycode: Self.backKeycode))
            client.send(.injectKeycode(action: .up, keycode: Self.backKeycode))
        }
    }

    private func close() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        client?.stop()
        // The media is paused and the app stays alive in the emulator, resuming where it was next time (ADR 0014).
        if let runtime { Task { try? await runtime.pauseMedia(); try? await runtime.pressHome() } }
    }
}
