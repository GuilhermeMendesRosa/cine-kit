import CineKitCore
import Foundation
import os

/// Owns the Android on/off toggle, the runtime, which exists only once the SDK is installed, and the in-app install (ADR 0004, 0018).
@MainActor
@Observable
final class AndroidSetup {
    static let installMessage = "Baixa cerca de 1,5 GB do Google para abrir APKs no cine-kit. Ao instalar, você aceita os termos de licença do Android SDK (developer.android.com/studio/terms)."

    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "AndroidSetup")

    /// Nil without the Android SDK: the Android UI offers the install instead.
    private(set) var runtime: AndroidRuntime?
    private(set) var failure: String?
    /// Starts on when the SDK is already there, so an update keeps the Android apps.
    private(set) var isEnabled = UserDefaults.standard.object(forKey: "androidEnabled") as? Bool ?? AndroidSDK.default.isAvailable {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "androidEnabled") }
    }
    let installer = AndroidInstaller(sdk: .default, downloader: URLSessionDownloader(), runner: ProcessCommandRunner())

    var isInstalling: Bool { installer.state != .idle }

    init() {
        if AndroidSDK.default.isAvailable {
            runtime = AndroidRuntime(sdk: .default, runner: ProcessCommandRunner())
        }
    }

    func start() {
        guard isEnabled else { return }
        // On with the SDK incomplete, e.g. after a failed or interrupted install: finishes it.
        guard let runtime else { return install() }
        // A failure here is retried when an Android app is opened.
        let resolution = UserDefaults.standard.string(forKey: "androidResolution").flatMap(AndroidRuntime.Resolution.init) ?? .hd1080
        Task { try? await runtime.start(resolution: resolution) }
    }

    func enable() {
        isEnabled = true
        if runtime == nil {
            install()
        } else {
            start()
        }
    }

    /// Keeps the SDK and the Android apps, so turning it back on downloads nothing.
    func disable() {
        guard !isInstalling else { return }
        isEnabled = false
        runtime?.stop()
    }

    private func install() {
        guard runtime == nil, !isInstalling else { return }
        failure = nil
        Task {
            do {
                try await installer.install()
                runtime = AndroidRuntime(sdk: .default, runner: ProcessCommandRunner())
                start()
            } catch {
                Self.logger.error("Android install failed: \(error)")
                failure = error.localizedDescription
                isEnabled = false
            }
        }
    }
}
