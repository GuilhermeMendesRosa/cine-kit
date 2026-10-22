import Testing
@testable import CineKitCore

struct AndroidKeyMapTests {
    @Test func arrowsMapToDpad() {
        #expect(AndroidKeyMap.action(keyCode: 123, characters: nil, modifiers: []) == .key(21))
        #expect(AndroidKeyMap.action(keyCode: 124, characters: nil, modifiers: []) == .key(22))
        #expect(AndroidKeyMap.action(keyCode: 125, characters: nil, modifiers: []) == .key(20))
        #expect(AndroidKeyMap.action(keyCode: 126, characters: nil, modifiers: []) == .key(19))
    }

    @Test func returnMapsToDpadCenter() {
        #expect(AndroidKeyMap.action(keyCode: 36, characters: "\r", modifiers: []) == .key(23))
    }

    @Test func spaceMapsToPlayPause() {
        #expect(AndroidKeyMap.action(keyCode: 49, characters: " ", modifiers: []) == .key(85))
    }

    @Test func deleteMapsToDel() {
        #expect(AndroidKeyMap.action(keyCode: 51, characters: "\u{7F}", modifiers: []) == .key(67))
    }

    @Test func printableCharactersBecomeText() {
        #expect(AndroidKeyMap.action(keyCode: 0, characters: "a", modifiers: []) == .text("a"))
    }

    @Test func escapeIsNotMapped() {
        #expect(AndroidKeyMap.action(keyCode: 53, characters: "\u{1B}", modifiers: []) == nil)
    }

    @Test func commandModifiedKeysAreIgnored() {
        #expect(AndroidKeyMap.action(keyCode: 12, characters: "q", modifiers: [.command]) == nil)
        #expect(AndroidKeyMap.action(keyCode: 123, characters: nil, modifiers: [.command]) == nil)
    }
}
