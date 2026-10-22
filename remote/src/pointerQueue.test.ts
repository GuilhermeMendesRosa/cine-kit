import { describe, expect, it, vi } from 'vitest'
import type { PointerEvent, PressResult } from './api'
import { createPointerQueue } from './pointerQueue'

/** A `send` whose requests stay in flight until `finish` is called. */
function pendingSend() {
  const finishers: ((result: PressResult) => void)[] = []
  const send = vi.fn((_: PointerEvent) => new Promise<PressResult>((resolve) => finishers.push(resolve)))
  return { send, finish: (result: PressResult = 'ok') => finishers.shift()!(result) }
}

const settle = () => new Promise((resolve) => setTimeout(resolve, 0))

describe('createPointerQueue', () => {
  it('keeps one request in flight', () => {
    const { send } = pendingSend()
    const queue = createPointerQueue(send, () => {})
    queue.moveTo(0.1, 0.1)
    queue.scroll(0, 5)
    queue.click()
    expect(send).toHaveBeenCalledTimes(1)
  })

  it('keeps only the latest position while waiting', async () => {
    const { send, finish } = pendingSend()
    const queue = createPointerQueue(send, () => {})
    queue.moveTo(0.1, 0.1)
    queue.moveTo(0.2, 0.3)
    queue.moveTo(0.5, 0.75)
    finish()
    await settle()
    expect(send.mock.calls.map(([event]) => event)).toEqual([
      { type: 'moveTo', x: 0.1, y: 0.1 },
      { type: 'moveTo', x: 0.5, y: 0.75 },
    ])
  })

  it('click goes after the pending position', async () => {
    const { send, finish } = pendingSend()
    const queue = createPointerQueue(send, () => {})
    queue.scroll(0, 10)
    queue.click()
    queue.moveTo(0.5, 0.5)
    finish()
    await settle()
    finish()
    await settle()
    expect(send.mock.calls.map(([event]) => event)).toEqual([
      { type: 'scroll', dx: 0, dy: 10 },
      { type: 'moveTo', x: 0.5, y: 0.5 },
      { type: 'click' },
    ])
  })

  it('reports offline/unauthorized', async () => {
    const { send, finish } = pendingSend()
    const onResult = vi.fn()
    const queue = createPointerQueue(send, onResult)
    queue.click()
    finish('unauthorized')
    await settle()
    queue.click()
    finish('offline')
    await settle()
    expect(onResult.mock.calls).toEqual([['unauthorized'], ['offline']])
  })
})
