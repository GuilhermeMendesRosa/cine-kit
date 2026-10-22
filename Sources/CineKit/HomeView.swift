import CineKitCore
import SwiftUI

struct HomeView: View {
    let apps: [StreamingApp]
    @Binding var focus: ShelfFocusState
    let onOpen: (StreamingApp) -> Void
    let onOpenSettings: () -> Void

    @FocusState private var hasKeyboardFocus: Bool

    private var heroApp: StreamingApp? {
        apps.indices.contains(focus.lastCard) ? apps[focus.lastCard] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            HStack {
                Spacer()
                GlassEffectContainer {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.largeTitle)
                            .padding(16)
                    }
                    .buttonStyle(.glass(focus.target == .settings ? .regular.tint(.accentColor) : .regular))
                }
            }
            .padding(.horizontal, 80)

            Spacer()

            Text(heroApp?.name ?? "")
                .font(.largeTitle.bold())
                .padding(.horizontal, 80)

            shelf
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [Color(hex: heroApp?.colorHex ?? "#000000").opacity(0.6), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut, value: focus.lastCard)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onMoveCommand { command in
            focus = ShelfFocus.move(focus, direction: MoveDirection(command), itemCount: apps.count)
        }
        .onKeyPress(.return) {
            guard case .card(let index) = focus.target else {
                onOpenSettings()
                return .handled
            }
            onOpen(apps[index])
            return .handled
        }
    }

    private var shelf: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        AppCardView(app: app, isFocused: focus.target == .card(index))
                            .id(index)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
            }
            .scrollClipDisabled()
            .onAppear { proxy.scrollTo(focus.lastCard, anchor: .center) }
            .onChange(of: focus.lastCard) { _, index in
                withAnimation { proxy.scrollTo(index, anchor: .center) }
            }
        }
    }
}

private extension MoveDirection {
    init(_ command: MoveCommandDirection) {
        switch command {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        @unknown default: self = .down
        }
    }
}
