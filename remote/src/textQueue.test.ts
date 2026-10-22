import { describe, expect, it, vi } from 'vitest'
import type { PressResult } from './api'
import { createTextQueue } from './textQueue'

/** A `send` whose requests stay in flight until `finish` is called. */
function pendingSend() {
  const finishers: ((result: PressResult) => void)[] = []
  const send = vi.fn((_: string) => new Promise<PressResult>((resolve) => finishers.push(resolve)))
  return { send, finish: (result: PressResult = 'ok') => finishers.shift()!(result) }
}

const settle = () => new Promise((resolve) => setTimeout(resolve, 0))

describe('createTextQueue', () => {
  it('joins text typed while waiting, in order', async () => {
    const { send, finish } = pendingSend()
    const queue = createTextQueue(send, () => {})
    queue.type('a')
    queue.type('b')
    queue.type('c')
    expect(send).toHaveBeenCalledTimes(1)
    finish()
    await settle()
    expect(send.mock.calls.map(([text]) => text)).toEqual(['a', 'bc'])
  })

  it('reports offline/unauthorized', async () => {
    const { send, finish } = pendingSend()
    const onResult = vi.fn()
    const queue = createTextQueue(send, onResult)
    queue.type('a')
    finish('offline')
    await settle()
    expect(onResult.mock.calls).toEqual([['offline']])
  })
})
