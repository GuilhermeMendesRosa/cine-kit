import { useMemo, type ReactNode } from 'react'
import { haptic } from './haptics'
import type { PointerQueue } from './pointerQueue'
import { createTouchpadGesture } from './touchpadGesture'

/** The Mac's mouse: the panel moves and clicks, the strip on its right edge scrolls (ADR 0012). */
export function Touchpad({ queue }: { queue: PointerQueue }) {
  return (
    <div className="touchpad glass">
      <Surface className="touchpad-area" label="Touchpad" queue={queue} />
      <Surface className="touchpad-strip" label="Rolagem" queue={queue} scrollOnly>
        <span className="grip" />
      </Surface>
    </div>
  )
}

function Surface({ className, label, queue, scrollOnly = false, children }: {
  className: string
  label: string
  queue: PointerQueue
  scrollOnly?: boolean
  children?: ReactNode
}) {
  const gesture = useMemo(() => createTouchpadGesture({
    onMove: queue.move,
    onScroll: queue.scroll,
    onClick: () => {
      haptic()
      queue.click()
    },
  }, { scrollOnly }), [queue, scrollOnly])

  return (
    <div
      className={className}
      aria-label={label}
      onPointerDown={(event) => {
        event.currentTarget.setPointerCapture(event.pointerId)
        gesture.down(event.pointerId, event.clientX, event.clientY, event.timeStamp)
      }}
      onPointerMove={(event) => gesture.move(event.pointerId, event.clientX, event.clientY, event.timeStamp)}
      onPointerUp={(event) => gesture.up(event.pointerId, event.timeStamp)}
      onPointerCancel={(event) => gesture.cancel(event.pointerId)}
    >
      {children}
    </div>
  )
}
