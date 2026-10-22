import AppKit
import CineKitCore

extension AppTheme {
    var appearance: NSAppearance {
        switch self {
        case .light: NSAppearance(named: .aqua)!
        case .dark: NSAppearance(named: .darkAqua)!
        }
    }
}
