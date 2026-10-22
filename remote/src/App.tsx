import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { pointer, press, type Button, type PressResult } from './api'
import { haptic } from './haptics'
import { startHold, startLongPress } from './holdRepeat'
import { clearToken, resolveToken } from './pairing'
import { createPointerQueue } from './pointerQueue'
import { Touchpad } from './Touchpad'
import './App.css'

const repeating = new Set<Button>(['up', 'down', 'left', 'right', 'volumeUp', 'volumeDown'])

export default function App() {
  const [token, setToken] = useState(() => resolveToken(new URL(location.href), localStorage))
  const [expired, setExpired] = useState(false)
  const [offline, setOffline] = useState(false)

  function handleResult(result: PressResult) {
    if (result === 'unauthorized') {
      clearToken(localStorage)
      setToken(null)
      setExpired(true)
    }
    setOffline(result === 'offline')
  }

  async function send(button: Button) {
    if (!token) return
    handleResult(await press(button, { token }))
  }

  const queue = useMemo(
    () => token ? createPointerQueue((event) => pointer(event, { token }), handleResult) : null,
    [token],
  )

  if (!token || !queue) {
    return (
      <main className="message">
        <h1>{expired ? 'Pareamento expirou' : 'cine-kit'}</h1>
        <p>{expired ? 'Escaneie de novo' : 'Escaneie'} o QR code em Configurações → Controle remoto, no cine-kit.</p>
      </main>
    )
  }

  return (
    <main className="remote">
      <p className="status" aria-live="polite">{offline ? 'Mac não encontrado' : ''}</p>
      <Touchpad queue={queue} />
      <div className="dpad glass">
        <Key button="up" label="Cima" onPress={send}><Chevron rotate={0} /></Key>
        <Key button="left" label="Esquerda" onPress={send}><Chevron rotate={-90} /></Key>
        <Key button="ok" label="OK" onPress={send}>OK</Key>
        <Key button="right" label="Direita" onPress={send}><Chevron rotate={90} /></Key>
        <Key button="down" label="Baixo" onPress={send}><Chevron rotate={180} /></Key>
      </div>
      <div className="actions">
        <Key button="back" longPress="home" label="Voltar; segure para o início" onPress={send}><BackIcon /></Key>
        <button
          type="button"
          className="key key-click glass"
          aria-label="Clique"
          onPointerDown={() => {
            haptic()
            queue.click()
          }}
        >
          <ClickIcon />
        </button>
        <Key button="playPause" label="Pause" onPress={send}><PlayPauseIcon /></Key>
        <span className="hint" aria-hidden="true">segure: início</span>
      </div>
      <div className="volume glass">
        <Key button="volumeDown" label="Diminuir volume" onPress={send}><VolumeIcon sign="−" /></Key>
        <Key button="volumeUp" label="Aumentar volume" onPress={send}><VolumeIcon sign="+" /></Key>
      </div>
    </main>
  )
}

function Key({ button, longPress, label, onPress, children }: {
  button: Button
  /** Sent instead of `button` when held for 600 ms. */
  longPress?: Button
  label: string
  onPress: (button: Button) => void
  children: ReactNode
}) {
  const stop = useRef<(() => void) | null>(null)

  function release() {
    stop.current?.()
    stop.current = null
  }

  useEffect(() => release, [])

  return (
    <button
      type="button"
      className={`key key-${button}`}
      aria-label={label}
      onPointerDown={() => {
        release()
        haptic()
        if (longPress) {
          stop.current = startLongPress(() => onPress(button), () => onPress(longPress))
        } else if (repeating.has(button)) {
          stop.current = startHold(() => onPress(button))
        } else {
          onPress(button)
        }
      }}
      onPointerUp={release}
      onPointerCancel={release}
      onPointerLeave={release}
    >
      {children}
    </button>
  )
}

// Icons drawn after SF Symbols, in the text color.
function Icon({ children, rotate = 0 }: { children: ReactNode; rotate?: number }) {
  return (
    <svg
      viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" strokeWidth="2.25"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{ transform: `rotate(${rotate}deg)` }}
    >
      {children}
    </svg>
  )
}

function Chevron({ rotate }: { rotate: number }) {
  return <Icon rotate={rotate}><path d="m6 15 6-6 6 6" /></Icon>
}

function BackIcon() {
  return <Icon><path d="M9 14 4 9l5-5" /><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11" /></Icon>
}

function ClickIcon() {
  return (
    <Icon>
      <path d="m9 9 5 12 1.8-5.2L21 14Z" fill="currentColor" />
      <path d="M7.2 2.2 8 5.1M5.1 8 2.2 7.2M14 4.1 12 6M6 12l-1.9 2" />
    </Icon>
  )
}

function PlayPauseIcon() {
  return <Icon><path d="M3 5v14l9-7Z" fill="currentColor" /><path d="M16 5v14M21 5v14" /></Icon>
}

function VolumeIcon({ sign }: { sign: '−' | '+' }) {
  return (
    <Icon>
      <path d="M3 9.5v5h3.5L11 18.5v-13L6.5 9.5Z" fill="currentColor" />
      <path d={sign === '+' ? 'M15 12h6M18 9v6' : 'M15 12h6'} />
    </Icon>
  )
}
