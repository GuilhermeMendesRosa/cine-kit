import AppKit
import CineKitCore
import SwiftUI

/// Shows only the Android app: the stream starts once the app is in the foreground, so the launcher never shows (ADR 0004).
struct AndroidScreen: View {
    private enum Phase {
        case opening, playing, failed
    }

    let app: StreamingApp

    @Environment(AndroidRuntime.self) private var runtime: AndroidRuntime?
    @State private var phase = Phase.opening
    @State private var renderer = H264Renderer()
    @State private var client: ScrcpyClient?
    @State private var keyMonitor: Any?

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
                ScrcpyVideoView(renderer: renderer)
                    .ignoresSafeArea()
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
            try await runtime.ensureRunning(resolution: .hd1080)
            try await runtime.waitUntilBooted()
            try await runtime.launch(package: package)
            while try await runtime.foregroundPackage() != package {
                guard ContinuousClock.now < deadline else { throw AndroidRuntimeError.bootTimeout }
                try await Task.sleep(for: .milliseconds(250))
            }
            try Task.checkCancellation()
            let client = ScrcpyClient(sdk: .default, runner: ProcessCommandRunner())
            client.onVideoPacket = { renderer.enqueue($0, isConfig: $1) }
            self.client = client
            try await client.start()
            try Task.checkCancellation()
            installKeyMonitor(client)
            phase = .playing
        } catch {
            // Also covers leaving the screen while it was opening.
            client?.stop()
            phase = .failed
        }
    }

    private func installKeyMonitor(_ client: ScrcpyClient) {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
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

    private func close() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        client?.stop()
        // The app stays alive in the emulator and resumes where it was next time.
        if let runtime { Task { try? await runtime.pressHome() } }
    }
}
