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
    private static let tokenKey = "remoteToken"
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
        53: "\u{1B}",
    ]

    private(set) var state = State.running
    private(set) var token: String
    /// The open app's click sound setting, for `GET /api/state` (ADR 0015).
    var clickSound = true
    @ObservationIgnored private var listener: NWListener?

    init() {
        if let token = UserDefaults.standard.string(forKey: Self.tokenKey) {
            self.token = token
        } else {
            token = RemotePairing.makeToken()
            UserDefaults.standard.set(token, forKey: Self.tokenKey)
        }
    }

    /// Nil when the Mac has no Bonjour name.
    var pairingURL: URL? {
        guard let name = SCDynamicStoreCopyLocalHostName(nil) as String? else { return nil }
        return RemotePairing.url(host: "\(name).local", port: Self.port, token: token)
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

    /// Paired phones get 401 and have to scan the new QR code.
    func regenerateToken() {
        token = RemotePairing.makeToken()
        UserDefaults.standard.set(token, forKey: Self.tokenKey)
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
        let response = RemoteRoute.response(for: request, token: token, clickSound: clickSound) { path in
            folder.flatMap { try? Data(contentsOf: $0.appending(path: path)) }
        }
        if response.status == 400 {
            Self.logger.error("Rejected remote press: \(String(decoding: request.body, as: UTF8.self), privacy: .public)")
        }
        if let button = response.button { press(button) }
        if let pointer = response.pointer { SyntheticPointer.perform(pointer) }
        return response
    }

    private func press(_ button: RemoteButton) {
        switch button {
        case .volumeUp: SystemVolume.adjust(.up)
        case .volumeDown: SystemVolume.adjust(.down)
        case .mute: SystemVolume.toggleMute()
        default:
            for keystroke in RemoteKeyMap.keystrokes(for: button) {
                post(keystroke)
            }
        }
    }

    private func post(_ keystroke: Keystroke) {
        let characters = Self.characters[keystroke.keyCode] ?? ""
        var flags: NSEvent.ModifierFlags = keystroke.command ? .command : []
        if (123...126).contains(keystroke.keyCode) { flags.formUnion([.function, .numericPad]) }
        guard let event = NSEvent.keyEvent(
            with: keystroke.isDown ? .keyDown : .keyUp,
            location: .zero,
            modifierFlags: flags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: NSApp.keyWindow?.windowNumber ?? 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: keystroke.isRepeat,
            keyCode: keystroke.keyCode
        ) else { return }
        NSApp.postEvent(event, atStart: false)
    }
}
