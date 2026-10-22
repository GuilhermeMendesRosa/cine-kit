import { describe, expect, it, vi } from 'vitest'
import { createTouchpadGesture } from './touchpadGesture'

const rect = { left: 10, top: 20, width: 160, height: 90 }

function gesture() {
  const handlers = { onPosition: vi.fn(), onClick: vi.fn() }
  return { handlers, touchpad: createTouchpadGesture(handlers) }
}

describe('createTouchpadGesture', () => {
  it('touch moves the pointer to the normalized point', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 50, 65, 0, rect)
    expect(handlers.onPosition).toHaveBeenCalledWith(0.25, 0.5)
  })

  it('drag follows the finger, clamped to the area', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 90, 65, 0, rect)
    touchpad.move(1, 130, 110, 16, rect)
    touchpad.move(1, 200, 0, 32, rect)
    expect(handlers.onPosition.mock.calls).toEqual([[0.5, 0.5], [0.75, 1], [1, 0]])
  })

  it('quick short touch clicks after positioning', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 90, 65, 0, rect)
    touchpad.move(1, 93, 69, 50, rect)
    touchpad.up(1, 200)
    expect(handlers.onClick).toHaveBeenCalledTimes(1)
    expect(handlers.onPosition.mock.invocationCallOrder[0]).toBeLessThan(handlers.onClick.mock.invocationCallOrder[0])
  })

  it('long or moved touch is not a click', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 90, 65, 0, rect)
    touchpad.up(1, 300)
    touchpad.down(1, 90, 65, 1000, rect)
    touchpad.move(1, 110, 65, 1050, rect)
    touchpad.up(1, 1100)
    expect(handlers.onClick).not.toHaveBeenCalled()
  })

  it('extra fingers are ignored', () => {
    const { handlers, touchpad } = gesture()
    touchpad.down(1, 90, 65, 0, rect)
    touchpad.down(2, 170, 110, 10, rect)
    touchpad.move(2, 150, 100, 20, rect)
    touchpad.up(2, 30)
    touchpad.up(1, 100)
    expect(handlers.onPosition.mock.calls).toEqual([[0.5, 0.5]])
    expect(handlers.onClick).toHaveBeenCalledTimes(1)
  })
})
