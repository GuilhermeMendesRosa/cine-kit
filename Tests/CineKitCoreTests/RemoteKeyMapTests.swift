import Testing
@testable import CineKitCore

struct RemoteKeyMapTests {
    private func press(_ keyCode: UInt16, command: Bool = false) -> [Keystroke] {
        [
            Keystroke(keyCode: keyCode, command: command, isDown: true, isRepeat: false),
            Keystroke(keyCode: keyCode, command: command, isDown: false, isRepeat: false),
        ]
    }

    @Test func arrowsOkAndPlayPausePressOnce() {
        #expect(RemoteKeyMap.keystrokes(for: .left) == press(123))
        #expect(RemoteKeyMap.keystrokes(for: .right) == press(124))
        #expect(RemoteKeyMap.keystrokes(for: .down) == press(125))
        #expect(RemoteKeyMap.keystrokes(for: .up) == press(126))
        #expect(RemoteKeyMap.keystrokes(for: .ok) == press(36))
        #expect(RemoteKeyMap.keystrokes(for: .playPause) == press(49))
    }

    @Test func deleteIsDelete() {
        #expect(RemoteKeyMap.keystrokes(for: .delete) == press(51))
    }

    @Test func backIsEscape() {
        #expect(RemoteKeyMap.keystrokes(for: .back) == press(53))
    }

    @Test func homeIsHeldEscape() {
        #expect(RemoteKeyMap.keystrokes(for: .home) == [
            Keystroke(keyCode: 53, command: false, isDown: true, isRepeat: false),
            Keystroke(keyCode: 53, command: false, isDown: true, isRepeat: true),
            Keystroke(keyCode: 53, command: false, isDown: false, isRepeat: false),
        ])
    }

    @Test func volumeButtonsHaveNoKeystrokes() {
        #expect(RemoteKeyMap.keystrokes(for: .volumeUp) == [])
        #expect(RemoteKeyMap.keystrokes(for: .volumeDown) == [])
        #expect(RemoteKeyMap.keystrokes(for: .mute) == [])
    }

    @Test func powerHasNoKeystrokes() {
        #expect(RemoteKeyMap.keystrokes(for: .power) == [])
    }
}
