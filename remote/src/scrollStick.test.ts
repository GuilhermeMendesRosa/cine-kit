import { describe, expect, it, vi } from 'vitest'
import { createScrollStick, stickSpeed } from './scrollStick'

describe('stickSpeed', () => {
  it('is zero inside the dead zone', () => {
    expect(stickSpeed(0)).toBe(0)
    expect(stickSpeed(0.1)).toBe(0)
    expect(stickSpeed(-0.1)).toBe(0)
  })

  it('reaches 2000 px/s at the ends, with the sign of the offset', () => {
    expect(stickSpeed(1)).toBe(2000)
    expect(stickSpeed(-1)).toBe(-2000)
  })

  it('grows with the distance from the center', () => {
    const speeds = [0.2, 0.4, 0.6, 0.8, 1].map(stickSpeed)
    expect(speeds[0]).toBeGreaterThan(0)
    speeds.slice(1).forEach((speed, i) => expect(speed).toBeGreaterThan(speeds[i]))
  })
})

/** A `requestFrame` driven by hand: `frame(t)` runs the scheduled callback at time `t` (ms). */
function manualFrames() {
  let callback: FrameRequestCallback | null = null
  const requestFrame = vi.fn((next: FrameRequestCallback) => {
    callback = next
    return 1
  })
  const cancelFrame = vi.fn(() => { callback = null })
  const frame = (t: number) => {
    const run = callback
    callback = null
    run?.(t)
  }
  return { requestFrame, cancelFrame, frame }
}

describe('createScrollStick', () => {
  it('emits per frame while held, down scrolls negative', () => {
    const { requestFrame, cancelFrame, frame } = manualFrames()
    const onScroll = vi.fn()
    const stick = createScrollStick({ onScroll, requestFrame, cancelFrame })
    stick.hold(1, 0)
    frame(100)
    frame(150)
    // 2000 px/s for 100 ms and then 50 ms; a finger below the center moves the page down.
    expect(onScroll.mock.calls).toEqual([[0, -200], [0, -100]])
  })

  it('stops after release', () => {
    const { requestFrame, cancelFrame, frame } = manualFrames()
    const onScroll = vi.fn()
    const stick = createScrollStick({ onScroll, requestFrame, cancelFrame })
    stick.hold(-1, 0)
    frame(100)
    stick.release()
    frame(200)
    expect(onScroll.mock.calls).toEqual([[0, 200]])
    expect(cancelFrame).toHaveBeenCalled()
  })
})
