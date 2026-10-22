import AppKit

/// The look of the menus, chosen in the settings (ADR 0013). Media screens stay dark.
enum AppTheme: String, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: "Automático"
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }

    /// Nil follows the system.
    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
