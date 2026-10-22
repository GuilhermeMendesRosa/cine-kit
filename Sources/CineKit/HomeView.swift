import CineKitCore
import SwiftUI

struct HomeView: View {
    let apps: [StreamingApp]
    @Binding var focus: ShelfFocusState
    let onOpen: (StreamingApp) -> Void
    let onOpenSettings: () -> Void

    @Environment(InputMode.self) private var inputMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 48) {
            HStack {
                TimelineView(.everyMinute) { context in
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                }
                Spacer()
                GlassEffectContainer {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.largeTitle)
                            .padding(16)
                    }
                    .buttonStyle(.glass(focus.target == .settings ? .regular.tint(.accentColor) : .regular))
                    .onHover { if $0, inputMode.kind == .pointer { focus.target = .settings } }
                }
            }
            .padding(.horizontal, 80)

            Spacer()

            VStack(spacing: 32) {
                shelf
                // A space keeps the layout still while the settings button has the focus.
                Text(focusedApp?.name ?? " ")
                    .font(.title.bold())
            }
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background }
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

    private var focusedApp: StreamingApp? {
        guard case .card(let index) = focus.target, apps.indices.contains(index) else { return nil }
        return apps[index]
    }

    /// Tinted by the last focused app, as the Apple TV home takes the color of the focused item.
    private var background: some View {
        let color = apps.indices.contains(focus.lastCard) ? Color(hex: apps[focus.lastCard].colorHex) : .clear
        return LinearGradient(colors: [color.opacity(0.35), color.opacity(0)], startPoint: .top, endPoint: .bottom)
            .background(Color(nsColor: .windowBackgroundColor))
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: focus.lastCard)
    }

    private var shelf: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        AppCardView(app: app, isFocused: focus.target == .card(index))
                            .id(index)
                            // While pointing, focus follows the pointer so the arrows continue from there (ADR 0012).
                            .onHover { if $0, inputMode.kind == .pointer { focus = ShelfFocusState(target: .card(index), lastCard: index) } }
                            .onTapGesture { onOpen(app) }
                    }
                }
                .padding(20)
            }
            .background(RoundedRectangle(cornerRadius: 40).fill(.fill.tertiary))
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .padding(.horizontal, 80)
            .onAppear { proxy.scrollTo(focus.lastCard, anchor: .center) }
            .onChange(of: focus.lastCard) { _, index in
                // Scrolling under a still pointer would put another card under it.
                guard inputMode.kind == .keys else { return }
                withAnimation { proxy.scrollTo(index, anchor: .center) }
            }
        }
    }
}

extension MoveDirection {
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
