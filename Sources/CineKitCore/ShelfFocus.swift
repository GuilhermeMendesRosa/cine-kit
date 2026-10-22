public enum ShelfFocusTarget: Hashable, Sendable {
    case settings
    case card(Int)
}

public enum MoveDirection: Sendable {
    case up, down, left, right
}

public struct ShelfFocusState: Hashable, Sendable {
    public var target: ShelfFocusTarget
    public var lastCard: Int

    public init(target: ShelfFocusTarget, lastCard: Int) {
        self.target = target
        self.lastCard = lastCard
    }
}

public enum ShelfFocus {
    public static func move(_ state: ShelfFocusState, direction: MoveDirection, itemCount: Int) -> ShelfFocusState {
        guard case .card(let index) = state.target else {
            guard direction == .down, itemCount > 0 else { return state }
            return ShelfFocusState(target: .card(state.lastCard), lastCard: state.lastCard)
        }
        let next: Int
        switch direction {
        case .up: return ShelfFocusState(target: .settings, lastCard: index)
        case .left: next = max(index - 1, 0)
        case .right: next = min(index + 1, itemCount - 1)
        case .down: next = index
        }
        return ShelfFocusState(target: .card(next), lastCard: next)
    }
}
