import Foundation

extension Bundle {
    /// The SwiftPM resource bundle. `Bundle.module` only looks next to the .app and in the build folder of the
    /// machine that compiled it, so the packaged app crashes elsewhere; scripts/bundle.sh puts it in Contents/Resources.
    static let resources: Bundle = Bundle.main.url(forResource: "CineKit_CineKit", withExtension: "bundle")
        .flatMap(Bundle.init(url:)) ?? .module
}
