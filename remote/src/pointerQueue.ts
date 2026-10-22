import type { PointerEvent, PressResult } from './api'

export type PointerQueue = ReturnType<typeof createPointerQueue>

/**
 * Sends touchpad events one request at a time, so the network never queues up: moves and scrolls add up while a
 * request is in flight, and a click goes after the pending move, where the pointer is meant to be (ADR 0012).
 */
export function createPointerQueue(
  send: (event: PointerEvent) => Promise<PressResult>,
  onResult: (result: PressResult) => void,
) {
  const move = { dx: 0, dy: 0 }
  const scroll = { dx: 0, dy: 0 }
  let clicks = 0
  let inFlight = false

  function next(): PointerEvent | null {
    for (const [type, delta] of [['move', move], ['scroll', scroll]] as const) {
      if (delta.dx !== 0 || delta.dy !== 0) {
        const event = { type, dx: delta.dx, dy: delta.dy }
        delta.dx = 0
        delta.dy = 0
        return event
      }
    }
    if (clicks === 0) return null
    clicks -= 1
    return { type: 'click' }
  }

  async function pump() {
    if (inFlight) return
    const event = next()
    if (!event) return
    inFlight = true
    const result = await send(event)
    inFlight = false
    onResult(result)
    void pump()
  }

  return {
    move(dx: number, dy: number) {
      move.dx += dx
      move.dy += dy
      void pump()
    },
    scroll(dx: number, dy: number) {
      scroll.dx += dx
      scroll.dy += dy
      void pump()
    },
    click() {
      clicks += 1
      void pump()
    },
  }
}
