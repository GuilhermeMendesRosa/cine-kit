/// A control of the settings, in a grid of rows that may have different lengths (ADR 0013).
public struct SettingsFocusTarget: Hashable, Sendable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

/// Arrow navigation of the settings: the focus layer of ADR 0007, extended to a grid.
public enum SettingsFocus {
    /// ↑↓ change rows, keeping the column within the new row; ←→ change columns. Stops at the edges.
    public static func move(_ target: SettingsFocusTarget, direction: MoveDirection, columnCounts: [Int]) -> SettingsFocusTarget {
        var row = target.row
        var column = target.column
        switch direction {
        case .up: row = max(row - 1, 0)
        case .down: row = min(row + 1, columnCounts.count - 1)
        case .left: column = max(column - 1, 0)
        case .right: column = min(column + 1, columnCounts[row] - 1)
        }
        return SettingsFocusTarget(row: row, column: min(column, columnCounts[row] - 1))
    }
}
