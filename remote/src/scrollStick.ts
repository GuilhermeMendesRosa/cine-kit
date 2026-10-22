// Scroll strip of ADR 0015, like an analog stick: the center is the dead zone, and the speed grows with the distance.
const deadZone = 0.1
const maxSpeed = 2000
const exponent = 1.6

/** Scroll speed in px/s for an offset from the center in [-1, 1] (negative = above the center). */
export function stickSpeed(offset: number): number {
  const distance = Math.abs(offset)
  if (distance <= deadZone) return 0
  return Math.sign(offset) * maxSpeed * ((distance - deadZone) / (1 - deadZone)) ** exponent
}

/** While held, scrolls once per frame by the speed of the offset. */
export function createScrollStick({ onScroll, requestFrame = requestAnimationFrame, cancelFrame = cancelAnimationFrame }: {
  onScroll: (dx: number, dy: number) => void
  requestFrame?: (callback: FrameRequestCallback) => number
  cancelFrame?: (handle: number) => void
}) {
  let offset = 0
  let last = 0
  let frame: number | null = null

  function tick(t: number) {
    // A finger below the center scrolls the page down; the Mac follows the finger, so the delta is negative.
    const dy = -stickSpeed(offset) * (t - last) / 1000
    last = t
    if (dy !== 0) onScroll(0, dy)
    frame = requestFrame(tick)
  }

  return {
    hold(nextOffset: number, t: number) {
      offset = nextOffset
      if (frame !== null) return
      last = t
      frame = requestFrame(tick)
    },
    release() {
      if (frame !== null) cancelFrame(frame)
      frame = null
      offset = 0
    },
  }
}
