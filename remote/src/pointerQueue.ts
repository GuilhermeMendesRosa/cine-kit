import type { PointerEvent, PressResult } from './api'

export type PointerQueue = ReturnType<typeof createPointerQueue>

/**
 * Sends touchpad events one request at a time, so the network never queues up: scrolls add up while a
 * request is in flight (ADR 0012), only the latest position is kept (ADR 0015), and a click goes after the pending
 * position, where the pointer is meant to be.
 */
export function createPointerQueue(
  send: (event: PointerEvent) => Promise<PressResult>,
  onResult: (result: PressResult) => void,
) {
  let position: { x: number; y: number } | null = null
  const scroll = { dx: 0, dy: 0 }
  let clicks = 0
  let inFlight = false

  function next(): PointerEvent | null {
    if (position) {
      const event = { type: 'moveTo' as const, ...position }
      position = null
      return event
    }
    if (scroll.dx !== 0 || scroll.dy !== 0) {
      const event = { type: 'scroll' as const, dx: scroll.dx, dy: scroll.dy }
      scroll.dx = 0
      scroll.dy = 0
      return event
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
    moveTo(x: number, y: number) {
      position = { x, y }
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
