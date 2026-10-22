import { useEffect, useRef, useState, type ReactNode } from 'react'
import { press, type Button } from './api'
import { startHold } from './holdRepeat'
import { clearToken, resolveToken } from './pairing'
import './App.css'

const repeating = new Set<Button>(['up', 'down', 'left', 'right', 'volumeUp', 'volumeDown'])

export default function App() {
  const [token, setToken] = useState(() => resolveToken(new URL(location.href), localStorage))
  const [expired, setExpired] = useState(false)
  const [offline, setOffline] = useState(false)

  async function send(button: Button) {
    if (!token) return
    const result = await press(button, { token })
    if (result === 'unauthorized') {
      clearToken(localStorage)
      setToken(null)
      setExpired(true)
    }
    setOffline(result === 'offline')
  }

  if (!token) {
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
      <div className="row">
        <Key button="back" label="Voltar" onPress={send}>‹</Key>
        <Key button="home" label="Home" onPress={send}>⌂</Key>
      </div>
      <div className="dpad">
        <Key button="up" label="Cima" onPress={send}>▲</Key>
        <Key button="left" label="Esquerda" onPress={send}>◀</Key>
        <Key button="ok" label="OK" onPress={send}>OK</Key>
        <Key button="right" label="Direita" onPress={send}>▶</Key>
        <Key button="down" label="Baixo" onPress={send}>▼</Key>
      </div>
      <div className="row">
        <Key button="playPause" label="Play/Pause" onPress={send}>⏯</Key>
      </div>
      <div className="row">
        <Key button="volumeDown" label="Diminuir volume" onPress={send}>−</Key>
        <Key button="mute" label="Mudo" onPress={send}>🔇</Key>
        <Key button="volumeUp" label="Aumentar volume" onPress={send}>+</Key>
      </div>
    </main>
  )
}

function Key({ button, label, onPress, children }: {
  button: Button
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
        if (repeating.has(button)) {
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
