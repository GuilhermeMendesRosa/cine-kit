import Testing
@testable import CineKitCore

struct SettingsFocusTests {
    // Theme (3 buttons), two app rows (4 buttons each), then the add/restore row (2 buttons).
    private let columnCounts = [3, 4, 4, 2]

    private func move(_ row: Int, _ column: Int, _ direction: MoveDirection) -> SettingsFocusTarget {
        SettingsFocus.move(SettingsFocusTarget(row: row, column: column), direction: direction, columnCounts: columnCounts)
    }

    @Test func downMovesToNextRow() {
        #expect(move(1, 2, .down) == SettingsFocusTarget(row: 2, column: 2))
    }

    @Test func downClampsColumnToShorterRow() {
        #expect(move(2, 3, .down) == SettingsFocusTarget(row: 3, column: 1))
    }

    @Test func upOnFirstRowStays() {
        #expect(move(0, 1, .up) == SettingsFocusTarget(row: 0, column: 1))
    }

    @Test func downOnLastRowStays() {
        #expect(move(3, 0, .down) == SettingsFocusTarget(row: 3, column: 0))
    }

    @Test func rightMovesColumn() {
        #expect(move(1, 0, .right) == SettingsFocusTarget(row: 1, column: 1))
    }

    @Test func rightOnLastColumnStays() {
        #expect(move(0, 2, .right) == SettingsFocusTarget(row: 0, column: 2))
    }

    @Test func leftOnFirstColumnStays() {
        #expect(move(2, 0, .left) == SettingsFocusTarget(row: 2, column: 0))
    }
}
