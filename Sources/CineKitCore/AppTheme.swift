/// The look of the menus, chosen in the settings and paired with the remote (ADRs 0013 and 0019). Media screens stay dark.
public enum AppTheme: String, CaseIterable, Sendable {
    case light, dark

    public var title: String {
        switch self {
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }
}
