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
    queue.move(1, 1)
    queue.scroll(0, 5)
    queue.click()
    expect(send).toHaveBeenCalledTimes(1)
  })

  it('coalesces moves while waiting', async () => {
    const { send, finish } = pendingSend()
    const queue = createPointerQueue(send, () => {})
    queue.move(1, 1)
    queue.move(1, 2)
    queue.move(3, 4)
    finish()
    await settle()
    expect(send.mock.calls.map(([event]) => event)).toEqual([
      { type: 'move', dx: 1, dy: 1 },
      { type: 'move', dx: 4, dy: 6 },
    ])
  })

  it('sends pending move before click', async () => {
    const { send, finish } = pendingSend()
    const queue = createPointerQueue(send, () => {})
    queue.scroll(0, 10)
    queue.click()
    queue.move(5, 5)
    finish()
    await settle()
    finish()
    await settle()
    expect(send.mock.calls.map(([event]) => event)).toEqual([
      { type: 'scroll', dx: 0, dy: 10 },
      { type: 'move', dx: 5, dy: 5 },
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
