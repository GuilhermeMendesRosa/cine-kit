import CineKitCore
import SwiftUI

struct ServiceScreen: View {
    let app: StreamingApp
    let onExit: () -> Void
    @State private var failed = false
    @Environment(WebViewCache.self) private var cache

    var body: some View {
        if failed {
            VStack(spacing: 24) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 96))
                Text("Não foi possível abrir \(app.name).")
                    .font(.largeTitle.bold())
                Text("Esc para voltar")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else {
            ServiceWebView(app: app, onExit: onExit) { cache.discard(app.id); failed = true }
                .ignoresSafeArea()
        }
    }
}
