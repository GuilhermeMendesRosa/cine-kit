import Testing
@testable import CineKitCore

struct RemoteKeyMapTests {
    private static let screens: [RemoteScreen] = [.android, .web, .other]

    private func press(_ keyCode: UInt16, command: Bool = false) -> [Keystroke] {
        [
            Keystroke(keyCode: keyCode, command: command, isDown: true, isRepeat: false),
            Keystroke(keyCode: keyCode, command: command, isDown: false, isRepeat: false),
        ]
    }

    @Test(arguments: screens) func arrowsOkAndPlayPausePressOnce(screen: RemoteScreen) {
        #expect(RemoteKeyMap.keystrokes(for: .left, screen: screen) == press(123))
        #expect(RemoteKeyMap.keystrokes(for: .right, screen: screen) == press(124))
        #expect(RemoteKeyMap.keystrokes(for: .down, screen: screen) == press(125))
        #expect(RemoteKeyMap.keystrokes(for: .up, screen: screen) == press(126))
        #expect(RemoteKeyMap.keystrokes(for: .ok, screen: screen) == press(36))
        #expect(RemoteKeyMap.keystrokes(for: .playPause, screen: screen) == press(49))
    }

    @Test func backOnWebIsCommandBracket() {
        #expect(RemoteKeyMap.keystrokes(for: .back, screen: .web) == press(33, command: true))
    }

    @Test(arguments: [RemoteScreen.android, .other]) func backElsewhereIsEscape(screen: RemoteScreen) {
        #expect(RemoteKeyMap.keystrokes(for: .back, screen: screen) == press(53))
    }

    @Test(arguments: screens) func homeIsHeldEscape(screen: RemoteScreen) {
        #expect(RemoteKeyMap.keystrokes(for: .home, screen: screen) == [
            Keystroke(keyCode: 53, command: false, isDown: true, isRepeat: false),
            Keystroke(keyCode: 53, command: false, isDown: true, isRepeat: true),
            Keystroke(keyCode: 53, command: false, isDown: false, isRepeat: false),
        ])
    }

    @Test(arguments: screens) func volumeButtonsHaveNoKeystrokes(screen: RemoteScreen) {
        #expect(RemoteKeyMap.keystrokes(for: .volumeUp, screen: screen) == [])
        #expect(RemoteKeyMap.keystrokes(for: .volumeDown, screen: screen) == [])
        #expect(RemoteKeyMap.keystrokes(for: .mute, screen: screen) == [])
    }
}
