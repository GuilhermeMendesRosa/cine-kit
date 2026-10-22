// Touchpad rules of ADR 0012, with the gain of ADR 0015: one finger moves, a quick touch clicks, two fingers scroll.
const clickMaxMs = 250
const clickMaxDistance = 10
const scrollGain = 2
const maxGain = 8

/** Faster swipes travel further, like a Mac trackpad: gain 3 + 4 × speed (px/ms), at most 8. */
export function accelerate(dx: number, dy: number, dtMs: number) {
  const speed = Math.hypot(dx, dy) / Math.max(dtMs, 1)
  const gain = Math.min(maxGain, 3 + 4 * speed)
  return { dx: dx * gain, dy: dy * gain }
}

type Handlers = {
  onMove: (dx: number, dy: number) => void
  onScroll: (dx: number, dy: number) => void
  onClick: () => void
}

/** Turns pointer positions (by pointer id, with timestamps in ms) into moves, scrolls and clicks. */
export function createTouchpadGesture({ onMove, onScroll, onClick }: Handlers) {
  const fingers = new Map<number, { x: number; y: number; t: number }>()
  // The touch that may still become a click: one finger that stayed close to where it started.
  let tap: { x: number; y: number; t: number } | null = null

  return {
    down(id: number, x: number, y: number, t: number) {
      fingers.set(id, { x, y, t })
      tap = fingers.size === 1 ? { x, y, t } : null
    },
    move(id: number, x: number, y: number, t: number) {
      const last = fingers.get(id)
      if (!last) return
      fingers.set(id, { x, y, t })
      const dx = x - last.x
      const dy = y - last.y
      if (tap && Math.hypot(x - tap.x, y - tap.y) > clickMaxDistance) tap = null
      if (fingers.size > 1) {
        onScroll((dx / fingers.size) * scrollGain, (dy / fingers.size) * scrollGain)
      } else {
        const moved = accelerate(dx, dy, t - last.t)
        onMove(moved.dx, moved.dy)
      }
    },
    up(id: number, t: number) {
      if (!fingers.delete(id)) return
      if (fingers.size === 0 && tap && t - tap.t <= clickMaxMs) onClick()
      if (fingers.size === 0) tap = null
    },
    cancel(id: number) {
      fingers.delete(id)
      tap = null
    },
  }
}
