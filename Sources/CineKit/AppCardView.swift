import CineKitCore
import SwiftUI

struct AppCardView: View {
    let app: StreamingApp
    let isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppCatalogStore.self) private var store

    private let shape = RoundedRectangle(cornerRadius: 20)

    var body: some View {
        artwork
            .frame(width: 280, height: 158)
            .clipShape(shape)
            .overlay {
                // Specular edge, as on tvOS; content gets no glass.
                shape
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                    .opacity(isFocused ? 1 : 0)
            }
            .shadow(color: .black.opacity(isFocused ? 0.35 : 0.1), radius: isFocused ? 20 : 4, y: isFocused ? 12 : 2)
            .scaleEffect(isFocused && !reduceMotion ? 1.1 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.25), value: isFocused)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = store.imageURL(for: app) ?? Bundle.resources.url(forResource: app.id, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // Defaults without a bundled cover show the brand name; custom apps without a photo show their initial.
            shape
                .fill(Color(hex: app.colorHex).gradient)
                .overlay {
                    Text(app.isDefault ? app.name : String(app.name.prefix(1)))
                        .font(app.isDefault ? .largeTitle.bold() : .system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
        }
    }
}

extension Color {
    /// Parses `#RRGGBB`; anything else falls back to gray.
    init(hex: String) {
        let value = UInt32(hex.trimmingPrefix("#"), radix: 16) ?? 0x808080
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
