import AppKit
import CineKitCore
import CoreImage.CIFilterBuiltins
import os
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "SettingsView")

    private enum FormTarget: Identifiable {
        case new
        case edit(StreamingApp)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let app): app.id
            }
        }
    }

    @Environment(AppCatalogStore.self) private var store
    @Environment(AndroidRuntime.self) private var androidRuntime: AndroidRuntime?
    @Environment(RemoteServer.self) private var remoteServer
    @State private var selection: StreamingApp.ID?
    @State private var formTarget: FormTarget?
    @State private var pendingRemoval: StreamingApp?
    @State private var confirmsRestore = false
    @State private var saveError: String?
    @State private var isInstalling = false
    @AppStorage("androidResolution") private var androidResolution = AndroidRuntime.Resolution.hd1080
    @FocusState private var listFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 24) {
                Text("Apps")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Adicionar app", systemImage: "plus") { formTarget = .new }
                    .keyboardShortcut("n")
                if let androidRuntime {
                    Button("Adicionar APK…", systemImage: "shippingbox") { addApk(with: androidRuntime) }
                }
                Button("Restaurar padrões", systemImage: "arrow.counterclockwise") { confirmsRestore = true }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            .controlSize(.extraLarge)

            if let androidRuntime {
                Picker("Resolução do Android", selection: $androidResolution) {
                    Text("1080p").tag(AndroidRuntime.Resolution.hd1080)
                    Text("4K").tag(AndroidRuntime.Resolution.uhd4k)
                }
                .font(.title2)
                .controlSize(.extraLarge)
                .fixedSize()
                .onChange(of: androidResolution) { _, resolution in
                    Task { try? await androidRuntime.restart(resolution: resolution) }
                }
            }

            remoteSection


            List(store.apps, selection: $selection) { app in
                HStack {
                    Text(app.name)
                        .font(.title)
                    Spacer()
                    Text(app.androidPackage ?? app.url.host() ?? "")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .focused($listFocused)
            .contextMenu(forSelectionType: StreamingApp.ID.self) { _ in } primaryAction: { ids in
                if let app = store.apps.first(where: { ids.contains($0.id) }) { formTarget = .edit(app) }
            }
            .onDeleteCommand {
                pendingRemoval = store.apps.first { $0.id == selection }
            }
        }
        .padding(80)
        .overlay {
            if isInstalling {
                ProgressView("Instalando…")
                    .controlSize(.extraLarge)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.6))
            }
        }
        .onAppear {
            selection = store.apps.first?.id
            listFocused = true
        }
        .sheet(item: $formTarget) { target in
            switch target {
            case .new:
                AppFormSheet(app: nil) { app in perform { try store.add(app) } }
            case .edit(let app):
                AppFormSheet(app: app) { app in perform { try store.update(app) } }
            }
        }
        .confirmationDialog(
            "Remover \(pendingRemoval?.name ?? "")?",
            isPresented: .constant(pendingRemoval != nil),
            presenting: pendingRemoval
        ) { app in
            Button("Remover", role: .destructive) {
                perform { try store.remove(id: app.id) }
                // Best effort: the card goes away even if the emulator is off.
                if let package = app.androidPackage, let androidRuntime {
                    Task {
                        do {
                            try await androidRuntime.uninstall(package: package)
                        } catch {
                            Self.logger.error("Uninstall of \(package, privacy: .public) failed: \(error)")
                        }
                    }
                }
            }
            Button("Cancelar", role: .cancel) { pendingRemoval = nil }
        }
        .confirmationDialog("Restaurar os apps padrão?", isPresented: $confirmsRestore) {
            Button("Restaurar") { perform { try store.restoreDefaults() } }
        } message: {
            Text("Os apps padrão voltam ao original. Os apps que você adicionou continuam.")
        }
        .alert("Não foi possível salvar", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var remoteSection: some View {
        HStack(spacing: 32) {
            if case .failed(let reason) = remoteServer.state {
                Text("Controle indisponível: \(reason)")
                    .font(.title2)
            } else if let url = remoteServer.pairingURL, let qrCode = Self.qrCode(for: url) {
                Image(nsImage: qrCode)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 200, height: 200)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Controle remoto")
                        .font(.title.bold())
                    Text("Escaneie com a câmera do celular, na mesma rede Wi-Fi.")
                        .font(.title2)
                    Text(url.absoluteString)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Button("Gerar novo código", systemImage: "qrcode") { remoteServer.regenerateToken() }
                        .controlSize(.extraLarge)
                }
            }
        }
    }

    private static func qrCode(for url: URL) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: image, size: output.extent.size)
    }

    private func addApk(with runtime: AndroidRuntime) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "apk") ?? .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        isInstalling = true
        Task {
            defer { isInstalling = false }
            do {
                // The emulator may still be booting right after the app opens.
                try await runtime.waitUntilBooted()
                let installed = try await runtime.install(apk: url)
                perform { try store.add(.android(package: installed.package, name: installed.label)) }
            } catch {
                saveError = "Não foi possível instalar o APK: \(error.localizedDescription)"
            }
        }
    }

    private func perform(_ change: () throws -> Void) {
        pendingRemoval = nil
        do {
            try change()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
