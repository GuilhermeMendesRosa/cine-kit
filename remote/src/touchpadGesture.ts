// Touchpad rules of ADR 0015: the area is a miniature of the screen, a quick touch clicks, extra fingers are ignored.
const clickMaxMs = 250
const clickMaxDistance = 10

type Handlers = {
  /** The touched point as a fraction 0...1 of the area, from its top left. */
  onPosition: (x: number, y: number) => void
  onClick: () => void
}

type Rect = { left: number; top: number; width: number; height: number }

const clamp = (value: number) => Math.min(1, Math.max(0, value))

/** Turns pointer positions (by pointer id, with timestamps in ms) into absolute positions and clicks. */
export function createTouchpadGesture({ onPosition, onClick }: Handlers) {
  let finger: number | null = null
  // The touch that may still become a click: it stayed close to where it started.
  let tap: { x: number; y: number; t: number } | null = null

  function position(x: number, y: number, rect: Rect) {
    onPosition(clamp((x - rect.left) / rect.width), clamp((y - rect.top) / rect.height))
  }

  return {
    down(id: number, x: number, y: number, t: number, rect: Rect) {
      if (finger !== null) return
      finger = id
      tap = { x, y, t }
      position(x, y, rect)
    },
    move(id: number, x: number, y: number, _t: number, rect: Rect) {
      if (id !== finger) return
      if (tap && Math.hypot(x - tap.x, y - tap.y) > clickMaxDistance) tap = null
      position(x, y, rect)
    },
    up(id: number, t: number) {
      if (id !== finger) return
      if (tap && t - tap.t <= clickMaxMs) onClick()
      finger = null
      tap = null
    },
    cancel(id: number) {
      if (id !== finger) return
      finger = null
      tap = null
    },
  }
}
