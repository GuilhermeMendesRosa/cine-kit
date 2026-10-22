import Testing
@testable import CineKitCore

struct ShelfFocusTests {
    @Test func rightMovesToNextCard() {
        let state = ShelfFocusState(target: .card(0), lastCard: 0)
        let moved = ShelfFocus.move(state, direction: .right, itemCount: 6)
        #expect(moved.target == .card(1))
    }

    @Test func rightOnLastCardStays() {
        let state = ShelfFocusState(target: .card(5), lastCard: 5)
        let moved = ShelfFocus.move(state, direction: .right, itemCount: 6)
        #expect(moved.target == .card(5))
    }

    @Test func leftOnFirstCardStays() {
        let state = ShelfFocusState(target: .card(0), lastCard: 0)
        let moved = ShelfFocus.move(state, direction: .left, itemCount: 6)
        #expect(moved.target == .card(0))
    }

    @Test func upFromCardFocusesSettingsAndRemembersCard() {
        let state = ShelfFocusState(target: .card(3), lastCard: 3)
        let moved = ShelfFocus.move(state, direction: .up, itemCount: 6)
        #expect(moved == ShelfFocusState(target: .settings, lastCard: 3))
    }

    @Test func downFromSettingsRestoresLastCard() {
        let state = ShelfFocusState(target: .settings, lastCard: 3)
        let moved = ShelfFocus.move(state, direction: .down, itemCount: 6)
        #expect(moved.target == .card(3))
    }

    @Test func downOnCardStays() {
        let state = ShelfFocusState(target: .card(2), lastCard: 2)
        let moved = ShelfFocus.move(state, direction: .down, itemCount: 6)
        #expect(moved.target == .card(2))
    }

    @Test func upOnSettingsStays() {
        let state = ShelfFocusState(target: .settings, lastCard: 2)
        let moved = ShelfFocus.move(state, direction: .up, itemCount: 6)
        #expect(moved.target == .settings)
    }

    @Test func emptyShelfKeepsSettings() {
        let state = ShelfFocusState(target: .settings, lastCard: 0)
        for direction in [MoveDirection.up, .down, .left, .right] {
            #expect(ShelfFocus.move(state, direction: direction, itemCount: 0).target == .settings)
        }
    }
}
