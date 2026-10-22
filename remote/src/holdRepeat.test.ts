import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { startHold, startLongPress } from './holdRepeat'

describe('startHold', () => {
  beforeEach(() => { vi.useFakeTimers() })
  afterEach(() => { vi.useRealTimers() })

  it('fires at once, after 400 ms and then every 120 ms', () => {
    const fire = vi.fn()
    startHold(fire)
    expect(fire).toHaveBeenCalledTimes(1)
    vi.advanceTimersByTime(399)
    expect(fire).toHaveBeenCalledTimes(1)
    vi.advanceTimersByTime(1)
    expect(fire).toHaveBeenCalledTimes(2)
    vi.advanceTimersByTime(120)
    expect(fire).toHaveBeenCalledTimes(3)
    vi.advanceTimersByTime(240)
    expect(fire).toHaveBeenCalledTimes(5)
  })

  it('stops firing when stopped', () => {
    const fire = vi.fn()
    const stop = startHold(fire)
    vi.advanceTimersByTime(400)
    stop()
    vi.advanceTimersByTime(1000)
    expect(fire).toHaveBeenCalledTimes(2)
  })
})

describe('startLongPress', () => {
  beforeEach(() => { vi.useFakeTimers() })
  afterEach(() => { vi.useRealTimers() })

  it('startLongPress fires short on early release', () => {
    const onShort = vi.fn()
    const onLong = vi.fn()
    const release = startLongPress(onShort, onLong)
    vi.advanceTimersByTime(599)
    release()
    vi.advanceTimersByTime(1000)
    expect(onShort).toHaveBeenCalledTimes(1)
    expect(onLong).not.toHaveBeenCalled()
  })

  it('fires long after 600 ms and not short', () => {
    const onShort = vi.fn()
    const onLong = vi.fn()
    const release = startLongPress(onShort, onLong)
    vi.advanceTimersByTime(600)
    expect(onLong).toHaveBeenCalledTimes(1)
    release()
    expect(onShort).not.toHaveBeenCalled()
  })
})
