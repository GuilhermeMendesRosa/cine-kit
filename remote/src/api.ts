export type Button =
  | 'up' | 'down' | 'left' | 'right' | 'ok' | 'back' | 'home'
  | 'playPause' | 'volumeUp' | 'volumeDown' | 'mute'

export type PressResult = 'ok' | 'unauthorized' | 'offline'

const timeoutMs = 2000

/** Sends a button to the Mac (ADR 0003, protocol v1). */
export async function press(
  button: Button,
  { token, fetch = globalThis.fetch }: { token: string; fetch?: typeof globalThis.fetch },
): Promise<PressResult> {
  try {
    const response = await fetch('/api/press', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ button }),
      signal: AbortSignal.timeout(timeoutMs),
    })
    if (response.ok) return 'ok'
    return response.status === 401 ? 'unauthorized' : 'offline'
  } catch {
    return 'offline'
  }
}
