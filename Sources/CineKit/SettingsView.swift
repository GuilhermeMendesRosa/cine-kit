import CineKitCore
import SwiftUI

struct SettingsView: View {
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
    @State private var selection: StreamingApp.ID?
    @State private var formTarget: FormTarget?
    @State private var pendingRemoval: StreamingApp?
    @State private var confirmsRestore = false
    @State private var saveError: String?
    @FocusState private var listFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 24) {
                Text("Apps")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Adicionar app", systemImage: "plus") { formTarget = .new }
                    .keyboardShortcut("n")
                Button("Restaurar padrões", systemImage: "arrow.counterclockwise") { confirmsRestore = true }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            .controlSize(.extraLarge)

            List(store.apps, selection: $selection) { app in
                HStack {
                    Text(app.name)
                        .font(.title)
                    Spacer()
                    Text(app.url.host() ?? "")
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
            Button("Remover", role: .destructive) { perform { try store.remove(id: app.id) } }
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

    private func perform(_ change: () throws -> Void) {
        pendingRemoval = nil
        do {
            try change()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
