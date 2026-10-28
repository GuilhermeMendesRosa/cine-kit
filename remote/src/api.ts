export type Button =
  | 'up' | 'down' | 'left' | 'right' | 'ok' | 'back' | 'home'
  | 'playPause' | 'volumeUp' | 'volumeDown' | 'mute' | 'delete' | 'power'

/** A touchpad event; scroll deltas are the finger's, which the content follows (ADR 0012). */
export type PointerEvent = { type: 'move' | 'scroll'; dx: number; dy: number } | { type: 'click' }

export type Theme = 'light' | 'dark'

export type PressResult = 'ok' | 'offline'

type Options = { fetch?: typeof globalThis.fetch }

const timeoutMs = 2000

/** Sends a button to the Mac (ADR 0003, protocol v1). */
export function press(button: Button, options: Options = {}): Promise<PressResult> {
  return post('/api/press', { button }, options)
}

/** Sends a touchpad event to the Mac (ADR 0012). */
export function pointer(event: PointerEvent, options: Options = {}): Promise<PressResult> {
  return post('/api/pointer', event, options)
}

/** Types text on the Mac, like its keyboard (ADR 0016). */
export function typeText(text: string, options: Options = {}): Promise<PressResult> {
  return post('/api/text', { text }, options)
}

/** Sets the theme of the Mac and the remote (ADR 0019). */
export function setTheme(theme: Theme, options: Options = {}): Promise<PressResult> {
  return post('/api/theme', { theme }, options)
}

/** Turns the Mac off in `minutes`; 0 cancels the timer (ADR 0024). */
export function setSleep(minutes: number, options: Options = {}): Promise<PressResult> {
  return post('/api/sleep', { minutes }, options)
}

/**
 * Reads the Mac's state for the remote: whether the open app wants the click sound (ADR 0015), the theme (ADR 0019),
 * whether the app is on (ADR 0021) and the seconds left on the sleep timer (ADR 0024).
 */
export async function fetchState(
  { fetch = globalThis.fetch }: Options = {},
): Promise<{ clickSound: boolean; theme: Theme; power: boolean; sleep: number | null } | 'offline'> {
  try {
    const response = await fetch('/api/state', { signal: AbortSignal.timeout(timeoutMs) })
    if (response.ok) {
      const json = await response.json()
      return {
        clickSound: json.clickSound === true,
        theme: json.theme === 'light' ? 'light' : 'dark',
        power: json.power === true,
        sleep: typeof json.sleep === 'number' ? json.sleep : null,
      }
    }
    return 'offline'
  } catch {
    return 'offline'
  }
}

async function post(path: string, body: object, { fetch = globalThis.fetch }: Options): Promise<PressResult> {
  try {
    const response = await fetch(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    })
    return response.ok ? 'ok' : 'offline'
  } catch {
    return 'offline'
  }
}
