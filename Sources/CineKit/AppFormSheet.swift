import AppKit
import CineKitCore
import SwiftUI
import UniformTypeIdentifiers

struct AppFormSheet: View {
    private static let customAppColorHex = "#5E5CE6"

    let app: StreamingApp?
    let onSave: (StreamingApp) -> Void

    @Environment(AppCatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var link: String
    @State private var imageFileName: String?
    @State private var imageError: String?

    init(app: StreamingApp?, onSave: @escaping (StreamingApp) -> Void) {
        self.app = app
        self.onSave = onSave
        _name = State(initialValue: app?.name ?? "")
        _link = State(initialValue: app?.url.absoluteString ?? "")
        _imageFileName = State(initialValue: app?.imageFileName)
    }

    private var validation: Result<ValidatedApp, AppDraftError> {
        AppDraft(name: name, link: link).validate()
    }

    /// Android apps keep their package; only the name and photo are editable (ADR 0004).
    private var isAndroid: Bool { app?.androidPackage != nil }

    private var canSave: Bool {
        isAndroid ? !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : (try? validation.get()) != nil
    }

    private var validationMessage: String? {
        guard !isAndroid, case .failure(let error) = validation, !(name.isEmpty && link.isEmpty) else { return nil }
        switch error {
        case .emptyName: return "Informe um nome."
        case .emptyLink: return "Informe um link."
        case .unsupportedScheme: return "Use um link http ou https."
        case .missingHost: return "O link não tem o endereço do site."
        }
    }

    var body: some View {
        Form {
            TextField("Nome", text: $name)
            if !isAndroid {
                TextField("Link", text: $link, prompt: Text("netflix.com"))
            }
            HStack {
                Text(imageFileName == nil ? "Sem foto" : "Foto escolhida")
                Spacer()
                if imageFileName != nil {
                    Button("Remover foto") { imageFileName = nil }
                }
                Button("Escolher foto…", action: chooseImage)
            }
            if let message = validationMessage ?? imageError {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .font(.title3)
        .frame(minWidth: 560)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar", action: save)
                    .disabled(!canSave)
            }
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            imageFileName = try store.importImage(from: url)
            imageError = nil
        } catch {
            imageError = "Não foi possível usar a foto: \(error.localizedDescription)"
        }
    }

    private func save() {
        if var saved = app, isAndroid {
            saved.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            saved.imageFileName = imageFileName
            onSave(saved)
            dismiss()
            return
        }
        guard case .success(let validated) = validation else { return }
        var saved = app ?? StreamingApp(
            id: UUID().uuidString,
            name: validated.name,
            url: validated.url,
            colorHex: Self.customAppColorHex,
            isDefault: false
        )
        saved.name = validated.name
        saved.url = validated.url
        saved.imageFileName = imageFileName
        onSave(saved)
        dismiss()
    }
}
