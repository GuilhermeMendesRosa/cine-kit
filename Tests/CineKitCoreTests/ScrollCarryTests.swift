import Testing
@testable import CineKitCore

struct ScrollCarryTests {
    @Test func wholePixelsPassThrough() {
        var carry = ScrollCarry()
        let pixels = carry.add(dx: 3, dy: -12)
        #expect(pixels.dx == 3 && pixels.dy == -12)
    }

    @Test func fractionsAddUpAcrossEvents() {
        var carry = ScrollCarry()
        // A slow scroll: half a pixel per frame is one pixel every other frame, not zero forever.
        let steps = (0..<4).map { _ in carry.add(dx: 0, dy: 0.5).dy }
        #expect(steps == [0, 1, 0, 1])
    }

    @Test func keepsTheFractionOfLargerDeltas() {
        var carry = ScrollCarry()
        let steps = (0..<5).map { _ in carry.add(dx: 0, dy: -1.9).dy }
        #expect(steps.reduce(0, +) == -9)
    }

    @Test func axesAreIndependent() {
        var carry = ScrollCarry()
        _ = carry.add(dx: 0.75, dy: 0.25)
        let pixels = carry.add(dx: 0.75, dy: 0.25)
        #expect(pixels.dx == 1 && pixels.dy == 0)
    }
}
