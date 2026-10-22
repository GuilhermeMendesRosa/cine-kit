import CineKitCore
import SwiftUI

struct ServiceScreen: View {
    let app: StreamingApp
    let onExit: () -> Void
    @State private var failed = false

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
            ServiceWebView(url: app.url, onExit: onExit) { failed = true }
                .ignoresSafeArea()
        }
    }
}
