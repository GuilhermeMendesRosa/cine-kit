import AppKit
import CineKitCore
import CoreImage.CIFilterBuiltins
import Network
import Observation
import os
import SystemConfiguration

/// Serves the web remote and its API on the local network (ADR 0003).
@MainActor
@Observable
final class RemoteServer {
    enum State: Equatable {
        case running
        case failed(String)
    }

    static let port = 8686
    private static let themeKey = "appTheme"
    private static let maxRequestSize = 64 * 1024
    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "RemoteServer")

    // Mac key code → characters AppKit puts in a real key event (arrows drive `onMoveCommand`).
    private static let characters: [UInt16: String] = [
        123: String(UnicodeScalar(NSLeftArrowFunctionKey)!),
        124: String(UnicodeScalar(NSRightArrowFunctionKey)!),
        125: String(UnicodeScalar(NSDownArrowFunctionKey)!),
        126: String(UnicodeScalar(NSUpArrowFunctionKey)!),
        36: "\r",
        49: " ",
        51: "\u{7F}",
        53: "\u{1B}",
    ]

    private(set) var state = State.running
    /// The open app's click sound setting, for `GET /api/state` (ADR 0015).
    var clickSound = true
    @ObservationIgnored private var listener: NWListener?

    /// Nil when the Mac has no Bonjour name.
    var pairingURL: URL? {
        guard let name = SCDynamicStoreCopyLocalHostName(nil) as String? else { return nil }
        return RemotePairing.url(host: "\(name).local", port: Self.port)
    }

    /// Nil when the Mac has no Bonjour name.
    var pairingQRCode: NSImage? { pairingURL.flatMap(Self.qrCode(for:)) }

    private static func qrCode(for url: URL) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: image, size: output.extent.size)
    }

    func start() {
        do {
            let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: UInt16(Self.port))!)
            listener.stateUpdateHandler = { [weak self] state in
                guard case .failed(let error) = state else { return }
                MainActor.assumeIsolated { self?.state = .failed(error.localizedDescription) }
            }
            listener.newConnectionHandler = { [weak self] connection in
                MainActor.assumeIsolated { self?.serve(connection) }
            }
            listener.start(queue: .main)
            self.listener = listener
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: .main)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Self.maxRequestSize) { [weak self] data, _, isComplete, error in
            MainActor.assumeIsolated {
                guard let self, error == nil else { return connection.cancel() }
                let buffer = buffer + (data ?? Data())
                if let request = RemoteHTTPRequest.parse(buffer) {
                    connection.send(content: self.respond(to: request).data, completion: .idempotent)
                    self.receive(on: connection, buffer: Data())
                } else if isComplete || buffer.count > Self.maxRequestSize {
                    connection.cancel()
                } else {
                    self.receive(on: connection, buffer: buffer)
                }
            }
        }
    }

    private func respond(to request: RemoteHTTPRequest) -> RemoteResponse {
        let folder = Bundle.main.resourceURL?.appending(path: "remote")
        let theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: Self.themeKey) ?? "") ?? .dark
        let response = RemoteRoute.response(for: request, clickSound: clickSound, theme: theme) { path in
            folder.flatMap { try? Data(contentsOf: $0.appending(path: path)) }
        }
        if response.status == 400 {
            Self.logger.error("Rejected remote press: \(String(decoding: request.body, as: UTF8.self), privacy: .public)")
        }
        if let button = response.button { press(button) }
        if let pointer = response.pointer { SyntheticPointer.perform(pointer) }
        if let text = response.text { type(text) }
        if let theme = response.theme { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
        return response
    }

    private func press(_ button: RemoteButton) {
        switch button {
        case .volumeUp: SystemVolume.adjust(.up)
        case .volumeDown: SystemVolume.adjust(.down)
        case .mute: SystemVolume.toggleMute()
        case .power: AppPower.toggle { press(.home) }
        default:
            for keystroke in RemoteKeyMap.keystrokes(for: button) {
                post(keystroke)
            }
        }
    }

    /// Types like a keyboard: one key press per character, which web views, text fields and Android all take (ADR 0016).
    private func type(_ text: String) {
        for character in text {
            for isDown in [true, false] {
                post(keyCode: 0, characters: String(character), flags: [], isDown: isDown, isRepeat: false)
            }
        }
    }

    private func post(_ keystroke: Keystroke) {
        var flags: NSEvent.ModifierFlags = keystroke.command ? .command : []
        if (123...126).contains(keystroke.keyCode) { flags.formUnion([.function, .numericPad]) }
        post(
            keyCode: keystroke.keyCode, characters: Self.characters[keystroke.keyCode] ?? "", flags: flags,
            isDown: keystroke.isDown, isRepeat: keystroke.isRepeat
        )
    }

    private func post(keyCode: UInt16, characters: String, flags: NSEvent.ModifierFlags, isDown: Bool, isRepeat: Bool) {
        guard let event = NSEvent.keyEvent(
            with: isDown ? .keyDown : .keyUp,
            location: .zero,
            modifierFlags: flags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: NSApp.keyWindow?.windowNumber ?? 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: isRepeat,
            keyCode: keyCode
        ) else { return }
        NSApp.postEvent(event, atStart: false)
    }
}
