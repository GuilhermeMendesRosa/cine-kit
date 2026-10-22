import CineKitCore
import SwiftUI

struct HomeView: View {
    let apps: [StreamingApp]
    @Binding var focus: ShelfFocusState
    let onOpen: (StreamingApp) -> Void
    let onOpenSettings: () -> Void

    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 48) {
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

            shelf
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light)
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
                HStack(spacing: 24) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        AppCardView(app: app, isFocused: focus.target == .card(index))
                            .id(index)
                    }
                }
                .padding(20)
            }
            .background(RoundedRectangle(cornerRadius: 40).fill(Color(white: 0.9)))
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .padding(.horizontal, 80)
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
