// Click sound of ADR 0015: a short synthesized tick, so there is no audio file to serve.
const frequencyHz = 1800
const volume = 0.25
const durationS = 0.03

/** Plays a tick on each press while enabled. The context is created on the first press, when the browser allows audio. */
export function createClickSound({ createContext = () => new AudioContext() }: { createContext?: () => AudioContext } = {}) {
  let context: AudioContext | null = null

  return {
    enabled: true,
    play() {
      if (!this.enabled) return
      context ??= createContext()
      if (context.state === 'suspended') void context.resume()
      const oscillator = context.createOscillator()
      const gain = context.createGain()
      const now = context.currentTime
      oscillator.type = 'triangle'
      oscillator.frequency.setValueAtTime(frequencyHz, now)
      gain.gain.setValueAtTime(volume, now)
      gain.gain.exponentialRampToValueAtTime(0.0001, now + durationS)
      oscillator.connect(gain).connect(context.destination)
      oscillator.start(now)
      oscillator.stop(now + durationS)
    },
  }
}
