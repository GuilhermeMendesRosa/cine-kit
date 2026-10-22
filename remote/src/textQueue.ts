import type { PressResult } from './api'

export type TextQueue = ReturnType<typeof createTextQueue>

/** Sends typed text one request at a time, joining what is typed while one is in flight, so letters keep their order (ADR 0016). */
export function createTextQueue(
  send: (text: string) => Promise<PressResult>,
  onResult: (result: PressResult) => void,
) {
  let pending = ''
  let inFlight = false

  async function pump() {
    if (inFlight || pending === '') return
    const text = pending
    pending = ''
    inFlight = true
    const result = await send(text)
    inFlight = false
    onResult(result)
    void pump()
  }

  return {
    type(text: string) {
      pending += text
      void pump()
    },
  }
}
