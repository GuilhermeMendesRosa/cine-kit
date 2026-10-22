import { describe, expect, it, vi } from 'vitest'
import { createClickSound } from './clickSound'

/** Just enough of an `AudioContext` to play the click. */
function fakeContext(state: AudioContextState = 'running') {
  const param = { setValueAtTime: vi.fn(), exponentialRampToValueAtTime: vi.fn() }
  const node = { connect: vi.fn().mockReturnThis(), start: vi.fn(), stop: vi.fn(), type: '', frequency: param, gain: param }
  return {
    state,
    currentTime: 0,
    destination: {},
    resume: vi.fn(),
    createOscillator: vi.fn(() => node),
    createGain: vi.fn(() => node),
    node,
  }
}

describe('createClickSound', () => {
  it('does not play when disabled', () => {
    const context = fakeContext()
    const createContext = vi.fn(() => context as unknown as AudioContext)
    const sound = createClickSound({ createContext })
    sound.enabled = false
    sound.play()
    expect(createContext).not.toHaveBeenCalled()
    expect(context.node.start).not.toHaveBeenCalled()
  })

  it('creates the context once, on the first play', () => {
    const context = fakeContext()
    const createContext = vi.fn(() => context as unknown as AudioContext)
    const sound = createClickSound({ createContext })
    expect(createContext).not.toHaveBeenCalled()
    sound.play()
    sound.play()
    expect(createContext).toHaveBeenCalledTimes(1)
    expect(context.node.start).toHaveBeenCalledTimes(2)
  })

  it('resumes a suspended context', () => {
    const context = fakeContext('suspended')
    const sound = createClickSound({ createContext: () => context as unknown as AudioContext })
    sound.play()
    expect(context.resume).toHaveBeenCalled()
  })
})
