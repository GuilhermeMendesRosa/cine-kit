import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { fetchState, pointer, press, setTheme, typeText, type Button, type PressResult } from './api'
import { createClickSound } from './clickSound'
import { haptic } from './haptics'
import { startHold } from './holdRepeat'
import { createPointerQueue } from './pointerQueue'
import { createTextQueue, type TextQueue } from './textQueue'
import { applyTheme, loadTheme, saveTheme } from './theme'
import { Touchpad } from './Touchpad'
import './App.css'

const repeating = new Set<Button>(['up', 'down', 'left', 'right', 'volumeUp', 'volumeDown'])
const stateIntervalMs = 1500
const clickSound = createClickSound()

/** The tick of each press: vibration where the phone allows it, and the click sound unless the open app turned it off. */
function feedback() {
  haptic()
  clickSound.play()
}

export default function App() {
  const [offline, setOffline] = useState(false)
  const [theme, setThemeState] = useState(() => loadTheme(localStorage))

  // The Mac's theme (ADR 0019).
  useEffect(() => {
    applyTheme(theme)
    saveTheme(theme, localStorage)
  }, [theme])

  function handleResult(result: PressResult) {
    setOffline(result === 'offline')
  }

  async function send(button: Button) {
    handleResult(await press(button))
  }

  // Optimistic: the phone switches at once; offline, the next /api/state brings back the Mac's theme.
  async function toggleTheme() {
    const next = theme === 'dark' ? 'light' : 'dark'
    setThemeState(next)
    handleResult(await setTheme(next))
  }

  // The open app may turn the click sound off (ADR 0015) and the Mac sets the theme (ADR 0019); offline keeps the last values.
  useEffect(() => {
    async function refresh() {
      if (document.visibilityState !== 'visible') return
      const state = await fetchState()
      if (state !== 'offline') {
        clickSound.enabled = state.clickSound
        setThemeState(state.theme)
      }
    }
    void refresh()
    const interval = setInterval(refresh, stateIntervalMs)
    document.addEventListener('visibilitychange', refresh)
    return () => {
      clearInterval(interval)
      document.removeEventListener('visibilitychange', refresh)
    }
  }, [])

  const queue = useMemo(() => createPointerQueue(pointer, handleResult), [])
  const textQueue = useMemo(() => createTextQueue(typeText, handleResult), [])

  return (
    <main className="remote">
      <p className="status" aria-live="polite">{offline ? 'Mac não encontrado' : ''}</p>
      <div className="top">
        <div className="top-row">
          <div className="volume glass">
            <Key button="volumeDown" label="Diminuir volume" onPress={send}><VolumeIcon sign="−" /></Key>
            <Key button="volumeUp" label="Aumentar volume" onPress={send}><VolumeIcon sign="+" /></Key>
          </div>
          <button
            type="button"
            className="key key-theme"
            aria-label="Alternar tema"
            onClick={() => {
              feedback()
              void toggleTheme()
            }}
          >
            <ThemeIcon />
          </button>
          <Key button="home" label="Início" onPress={send}><HomeIcon /></Key>
        </div>
        <div className="actions">
          <Key button="back" label="Voltar" onPress={send}><BackIcon /></Key>
          <KeyboardKey queue={textQueue} onPress={send} />
          <Key button="playPause" label="Pause" onPress={send}><PlayPauseIcon /></Key>
        </div>
      </div>
      <div className="dpad glass">
        <Key button="up" label="Cima" onPress={send}><Chevron rotate={0} /></Key>
        <Key button="left" label="Esquerda" onPress={send}><Chevron rotate={-90} /></Key>
        <Key button="ok" label="OK" onPress={send}>OK</Key>
        <Key button="right" label="Direita" onPress={send}><Chevron rotate={90} /></Key>
        <Key button="down" label="Baixo" onPress={send}><Chevron rotate={180} /></Key>
      </div>
      <Touchpad queue={queue} onTap={feedback} />
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
        feedback()
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

/** Opens the phone's keyboard; each letter goes to the Mac as it is typed, Delete and Enter as keys (ADR 0016). */
function KeyboardKey({ queue, onPress }: { queue: TextQueue; onPress: (button: Button) => void }) {
  const input = useRef<HTMLInputElement>(null)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const field = input.current!

    // Text leaves right away and the field stays empty, so the phone has nothing to autocorrect.
    function flush() {
      if (field.value === '') return
      queue.type(field.value)
      field.value = ''
    }

    function beforeInput(event: InputEvent) {
      if (event.inputType === 'deleteContentBackward' && field.value === '') {
        event.preventDefault()
        onPress('delete')
      }
    }

    function typed(event: Event) {
      if (!(event as InputEvent).isComposing) flush()
    }

    function keyDown(event: KeyboardEvent) {
      if (event.key !== 'Enter' || event.isComposing) return
      event.preventDefault()
      flush()
      onPress('ok')
      field.blur()
    }

    field.addEventListener('beforeinput', beforeInput)
    field.addEventListener('input', typed)
    field.addEventListener('compositionend', flush)
    field.addEventListener('keydown', keyDown)
    return () => {
      field.removeEventListener('beforeinput', beforeInput)
      field.removeEventListener('input', typed)
      field.removeEventListener('compositionend', flush)
      field.removeEventListener('keydown', keyDown)
    }
  }, [queue, onPress])

  return (
    <>
      <button
        type="button"
        className="key key-keyboard"
        aria-label={open ? 'Fechar teclado' : 'Teclado'}
        aria-pressed={open}
        // Keeps the focus on the field, so a second tap closes the keyboard instead of reopening it.
        onMouseDown={(event) => event.preventDefault()}
        onClick={() => {
          feedback()
          if (open) input.current!.blur()
          else input.current!.focus()
        }}
      >
        <KeyboardIcon />
      </button>
      <input
        ref={input}
        className="keyboard-field"
        type="text"
        aria-label="Texto para o Mac"
        autoComplete="off"
        autoCorrect="off"
        autoCapitalize="off"
        spellCheck={false}
        enterKeyHint="send"
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
      />
    </>
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

function HomeIcon() {
  return <Icon><path d="M3 11 12 3.5 21 11" /><path d="M5.5 9v11h13V9" /></Icon>
}

/** After `circle.lefthalf.filled`: a fixed icon, so it reads as "switch" and not as the current or the next theme. */
function ThemeIcon() {
  return <Icon><circle cx="12" cy="12" r="9" /><path d="M12 3a9 9 0 0 0 0 18Z" fill="currentColor" /></Icon>
}

function KeyboardIcon() {
  return (
    <Icon>
      <rect x="2.5" y="6" width="19" height="12" rx="2.5" />
      <path d="M6.5 10h.01M10 10h.01M14 10h.01M17.5 10h.01M8 14h8" />
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
