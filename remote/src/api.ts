export type Button =
  | 'up' | 'down' | 'left' | 'right' | 'ok' | 'back' | 'home'
  | 'playPause' | 'volumeUp' | 'volumeDown' | 'mute' | 'delete'

/** A touchpad event; scroll deltas are the finger's, which the content follows (ADR 0012). */
export type PointerEvent = { type: 'move' | 'scroll'; dx: number; dy: number } | { type: 'click' }

export type PressResult = 'ok' | 'unauthorized' | 'offline'

type Options = { token: string; fetch?: typeof globalThis.fetch }

const timeoutMs = 2000

/** Sends a button to the Mac (ADR 0003, protocol v1). */
export function press(button: Button, options: Options): Promise<PressResult> {
  return post('/api/press', { button }, options)
}

/** Sends a touchpad event to the Mac (ADR 0012). */
export function pointer(event: PointerEvent, options: Options): Promise<PressResult> {
  return post('/api/pointer', event, options)
}

/** Types text on the Mac, like its keyboard (ADR 0016). */
export function typeText(text: string, options: Options): Promise<PressResult> {
  return post('/api/text', { text }, options)
}

/** Reads the Mac's state for the remote: whether the open app wants the click sound (ADR 0015). */
export async function fetchState(
  { token, fetch = globalThis.fetch }: Options,
): Promise<{ clickSound: boolean } | 'unauthorized' | 'offline'> {
  try {
    const response = await fetch('/api/state', {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(timeoutMs),
    })
    if (response.ok) return { clickSound: (await response.json()).clickSound === true }
    return response.status === 401 ? 'unauthorized' : 'offline'
  } catch {
    return 'offline'
  }
}

async function post(path: string, body: object, { token, fetch = globalThis.fetch }: Options): Promise<PressResult> {
  try {
    const response = await fetch(path, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    })
    if (response.ok) return 'ok'
    return response.status === 401 ? 'unauthorized' : 'offline'
  } catch {
    return 'offline'
  }
}
