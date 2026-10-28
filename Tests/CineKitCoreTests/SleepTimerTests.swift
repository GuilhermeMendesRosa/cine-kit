import Foundation
import Testing
@testable import CineKitCore

struct SleepTimerTests {
    let start = Date(timeIntervalSinceReferenceDate: 1000)

    @Test func optionsAreTheTVValues() {
        #expect(SleepTimer.options == [15, 30, 45, 60, 90, 120])
    }

    @Test func remainingRoundsUpSeconds() {
        var timer = SleepTimer()
        timer.start(minutes: 30, now: start)
        #expect(timer.remaining(at: start + 0.5) == 1800)
        #expect(timer.remaining(at: start + 1799.2) == 1)
    }

    @Test func remainingIsNilAfterDeadline() {
        var timer = SleepTimer()
        timer.start(minutes: 30, now: start)
        #expect(timer.remaining(at: start + 1800) == nil)
    }

    @Test func zeroCancels() {
        var timer = SleepTimer()
        timer.start(minutes: 30, now: start)
        timer.start(minutes: 0, now: start)
        #expect(timer.deadline == nil)
        #expect(timer.remaining(at: start) == nil)
    }

    @Test func cancelClearsDeadline() {
        var timer = SleepTimer()
        timer.start(minutes: 30, now: start)
        timer.cancel()
        #expect(timer.deadline == nil)
        #expect(timer.remaining(at: start) == nil)
    }

    @Test func startReplacesDeadline() {
        var timer = SleepTimer()
        timer.start(minutes: 30, now: start)
        timer.start(minutes: 15, now: start)
        #expect(timer.remaining(at: start) == 900)
    }
}
