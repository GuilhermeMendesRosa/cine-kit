import { describe, expect, it, vi } from 'vitest'
import { accelerate, createTouchpadGesture } from './touchpadGesture'

function gesture(options?: { scrollOnly?: boolean }) {
  const handlers = { onMove: vi.fn(), onScroll: vi.fn(), onClick: vi.fn() }
  return { handlers, touchpad: createTouchpadGesture(handlers, options) }
}

describe('createTouchpadGesture', () => {
  it('one finger moves with acceleration', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 0, 0, 0)
    touchpad.move(1, 10, 0, 10) // 1 px/ms: gain 1.5 + 2 × 1 = 3.5
    expect(handlers.onMove).toHaveBeenCalledWith(35, 0)
    expect(handlers.onScroll).not.toHaveBeenCalled()
  })

  it('quick short touch is a click', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 100, 100, 0)
    touchpad.move(1, 103, 104, 50)
    touchpad.up(1, 200)
    expect(handlers.onClick).toHaveBeenCalledTimes(1)
  })

  it('long or moved touch is not a click', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 0, 0, 0)
    touchpad.up(1, 300)
    touchpad.down(1, 0, 0, 1000)
    touchpad.move(1, 20, 0, 1050)
    touchpad.up(1, 1100)
    expect(handlers.onClick).not.toHaveBeenCalled()
  })

  it('two fingers scroll', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 0, 0, 0)
    touchpad.down(2, 100, 0, 0)
    touchpad.move(1, 0, 10, 16)
    touchpad.move(2, 100, 10, 16)
    touchpad.up(1, 50)
    touchpad.up(2, 50)
    // Each finger adds half of its movement, twice as fast as the finger.
    expect(handlers.onScroll.mock.calls).toEqual([[0, 10], [0, 10]])
    expect(handlers.onMove).not.toHaveBeenCalled()
    expect(handlers.onClick).not.toHaveBeenCalled()
  })

  it('scrollOnly strip never moves', () => {
    const { handlers, touchpad } = gesture({ scrollOnly: true })
    touchpad.down(1, 0, 0, 0)
    touchpad.move(1, 5, 10, 16)
    touchpad.up(1, 50)
    expect(handlers.onScroll).toHaveBeenCalledWith(0, 20)
    expect(handlers.onMove).not.toHaveBeenCalled()
    expect(handlers.onClick).not.toHaveBeenCalled()
  })
})

describe('accelerate', () => {
  it('accelerate caps at 4x', () => {
    expect(accelerate(100, -50, 1)).toEqual({ dx: 400, dy: -200 })
  })
})
