import AppKit
import CineKitCore
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

    /// A button of the focus grid (ADR 0013).
    private struct Control {
        var title: String
        var subtitle: String?
        var systemImage: String?
        var isSelected = false
        var shortcut: KeyboardShortcut?
        var action: () -> Void
    }

    let onClose: () -> Void

    @Environment(AppCatalogStore.self) private var store
    @Environment(AndroidRuntime.self) private var androidRuntime: AndroidRuntime?
    @Environment(RemoteServer.self) private var remoteServer
    @Environment(InputMode.self) private var inputMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = SettingsFocusTarget(row: Self.themeRow, column: 0)
    @State private var formTarget: FormTarget?
    @State private var pendingRemoval: StreamingApp?
    @State private var confirmsRestore = false
    @State private var saveError: String?
    @State private var isInstalling = false
    @AppStorage("androidResolution") private var androidResolution = AndroidRuntime.Resolution.hd1080
    @AppStorage("appTheme") private var theme = AppTheme.dark
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        let rows = rows
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 56) {
                    HStack(spacing: 32) {
                        controls(rows, row: Self.backRow)
                        Text("Configurações")
                            .font(.largeTitle.bold())
                    }
                    section("Aparência") {
                        HStack(spacing: 16) {
                            Text("Tema")
                                .font(.title2)
                                .frame(width: 200, alignment: .leading)
                            controls(rows, row: Self.themeRow)
                        }
                    }
                    section("Apps") {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(store.apps.indices, id: \.self) { index in
                                controls(rows, row: Self.firstAppRow + index)
                            }
                            controls(rows, row: actionsRow)
                                .padding(.top, 16)
                        }
                    }
                    if androidRuntime != nil {
                        section("Android") {
                            HStack(spacing: 16) {
                                Text("Resolução")
                                    .font(.title2)
                                    .frame(width: 200, alignment: .leading)
                                controls(rows, row: actionsRow + 1)
                            }
                        }
                    }
                    section("Controle remoto") {
                        remoteSection(rows)
                    }
                }
                .frame(maxWidth: 1200, alignment: .leading)
                .padding(80)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: focus) { _, target in
                // Scrolling under a still pointer would put another control under it.
                guard inputMode.kind == .keys else { return }
                withAnimation(reduceMotion ? nil : .default) { proxy.scrollTo(target, anchor: .center) }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onMoveCommand { command in
            focus = SettingsFocus.move(focus, direction: MoveDirection(command), columnCounts: rows.map(\.count))
        }
        .onKeyPress(.return) {
            rows[focus.row][focus.column].action()
            return .handled
        }
        .onDeleteCommand {
            pendingRemoval = focusedApp
        }
        // Removing an app or the remote failing can shorten the grid.
        .onChange(of: rows.map(\.count)) { _, counts in
            let row = min(focus.row, counts.count - 1)
            focus = SettingsFocusTarget(row: row, column: min(focus.column, counts[row] - 1))
        }
        .onChange(of: androidResolution) { _, resolution in
            Task { try? await androidRuntime?.restart(resolution: resolution) }
        }
        .overlay {
            if isInstalling {
                ProgressView("Instalando…")
                    .controlSize(.extraLarge)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.6))
            }
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
            // OK confirms and Back cancels, from the remote too.
            .keyboardShortcut(.defaultAction)
            Button("Cancelar", role: .cancel) { pendingRemoval = nil }
        }
        .confirmationDialog("Restaurar os apps padrão?", isPresented: $confirmsRestore) {
            Button("Restaurar") { perform { try store.restoreDefaults() } }
        } message: {
            Text("Os apps padrão e a ordem original voltam. Os apps que você adicionou continuam, no fim.")
        }
        .alert("Não foi possível salvar", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // Rows of the focus grid: back, theme, one per app, add/restore, Android resolution (with the runtime), remote.
    private static let backRow = 0
    private static let themeRow = 1
    private static let firstAppRow = 2
    private var actionsRow: Int { Self.firstAppRow + store.apps.count }

    private var rows: [[Control]] {
        var rows = [
            [Control(title: "Voltar", systemImage: "chevron.left", action: onClose)],
            AppTheme.allCases.map { option in
                Control(title: option.title, isSelected: theme == option) { theme = option }
            },
        ]
        rows += store.apps.map(appControls)
        var actions = [Control(title: "Adicionar app", systemImage: "plus", shortcut: KeyboardShortcut("n")) { formTarget = .new }]
        if let androidRuntime {
            actions.append(Control(title: "Adicionar APK…", systemImage: "shippingbox") { addApk(with: androidRuntime) })
        }
        actions.append(Control(title: "Restaurar padrões", systemImage: "arrow.counterclockwise", shortcut: KeyboardShortcut("r", modifiers: [.command, .shift])) {
            confirmsRestore = true
        })
        rows.append(actions)
        if androidRuntime != nil {
            rows.append([AndroidRuntime.Resolution.hd1080, .uhd4k].map { resolution in
                Control(title: resolution == .hd1080 ? "1080p" : "4K", isSelected: androidResolution == resolution) {
                    androidResolution = resolution
                }
            })
        }
        if remoteServer.pairingURL != nil, remoteServer.state == .running {
            rows.append([Control(title: "Gerar novo código", systemImage: "qrcode") { remoteServer.regenerateToken() }])
        }
        return rows
    }

    private var focusedApp: StreamingApp? {
        let index = focus.row - Self.firstAppRow
        return store.apps.indices.contains(index) ? store.apps[index] : nil
    }

    private func appControls(_ app: StreamingApp) -> [Control] {
        [
            Control(title: app.name, subtitle: app.androidPackage ?? app.url.host() ?? "") { formTarget = .edit(app) },
            Control(title: "Subir", systemImage: "chevron.up") { move(app, by: -1) },
            Control(title: "Descer", systemImage: "chevron.down") { move(app, by: 1) },
            Control(title: "Remover", systemImage: "trash") { pendingRemoval = app },
        ]
    }

    /// The focus follows the moved app.
    private func move(_ app: StreamingApp, by offset: Int) {
        perform { try store.move(id: app.id, by: offset) }
        if let index = store.apps.firstIndex(where: { $0.id == app.id }) {
            focus.row = Self.firstAppRow + index
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func controls(_ rows: [[Control]], row: Int) -> some View {
        HStack(spacing: 16) {
            ForEach(rows[row].indices, id: \.self) { column in
                control(rows[row][column], at: SettingsFocusTarget(row: row, column: column))
            }
        }
    }

    /// Only the focused control gets glass, so there is one glass at a time.
    private func control(_ control: Control, at target: SettingsFocusTarget) -> some View {
        let isFocused = focus == target
        return Button(action: control.action) {
            HStack(spacing: 12) {
                if control.isSelected {
                    Image(systemName: "checkmark")
                } else if let systemImage = control.systemImage {
                    Image(systemName: systemImage)
                }
                Text(control.title)
                if let subtitle = control.subtitle {
                    Spacer(minLength: 24)
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.title2)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(maxWidth: control.subtitle == nil ? nil : .infinity, alignment: .leading)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(control.shortcut)
        .background { if !isFocused { Capsule().fill(.fill.quaternary) } }
        .glassEffect(isFocused ? .regular.interactive() : .identity, in: .capsule)
        .scaleEffect(isFocused && !reduceMotion ? 1.04 : 1)
        .animation(reduceMotion ? nil : .spring(duration: 0.25), value: isFocused)
        .onHover { if $0, inputMode.kind == .pointer { focus = target } }
        .id(target)
    }

    private func remoteSection(_ rows: [[Control]]) -> some View {
        HStack(spacing: 32) {
            if case .failed(let reason) = remoteServer.state {
                Text("Controle indisponível: \(reason)")
                    .font(.title2)
            } else if let url = remoteServer.pairingURL, let qrCode = remoteServer.pairingQRCode {
                Image(nsImage: qrCode)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 200, height: 200)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Escaneie com a câmera do celular, na mesma rede Wi-Fi.")
                        .font(.title2)
                    Text(url.absoluteString)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    controls(rows, row: rows.count - 1)
                }
            }
        }
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
