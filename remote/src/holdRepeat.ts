const delayMs = 400
const intervalMs = 120

/** Fires now and keeps firing while the button is held, like a TV remote. Returns `stop`. */
export function startHold(fire: () => void): () => void {
  let interval: ReturnType<typeof setInterval> | undefined
  fire()
  const delay = setTimeout(() => {
    fire()
    interval = setInterval(fire, intervalMs)
  }, delayMs)
  return () => {
    clearTimeout(delay)
    clearInterval(interval)
  }
}

/** Fires `onLong` once the button is held for `delayMs`, or `onShort` when released before. Returns `release`. */
export function startLongPress(onShort: () => void, onLong: () => void, delayMs = 600): () => void {
  let fired = false
  const delay = setTimeout(() => {
    fired = true
    onLong()
  }, delayMs)
  return () => {
    clearTimeout(delay)
    if (!fired) onShort()
    fired = true
  }
}
