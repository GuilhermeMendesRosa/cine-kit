import { useEffect, useMemo, useState, type PointerEvent } from 'react'
import type { PointerQueue } from './pointerQueue'
import { createScrollStick } from './scrollStick'
import { createTouchpadGesture } from './touchpadGesture'

const gripHalfHeight = 28

/** The Mac's mouse: the panel moves and clicks (ADR 0012), the strip on its right scrolls like a stick (ADR 0015). */
export function Touchpad({ queue, onTap }: { queue: PointerQueue; onTap: () => void }) {
  const gesture = useMemo(() => createTouchpadGesture({
    onMove: queue.move,
    onScroll: queue.scroll,
    onClick: () => {
      onTap()
      queue.click()
    },
  }), [queue, onTap])
  const stick = useMemo(() => createScrollStick({ onScroll: queue.scroll }), [queue])
  const [grip, setGrip] = useState<number | null>(null)

  useEffect(() => stick.release, [stick])

  function hold(event: PointerEvent<HTMLDivElement>) {
    const rect = event.currentTarget.getBoundingClientRect()
    const reach = rect.height / 2 - gripHalfHeight
    const offset = Math.min(1, Math.max(-1, (event.clientY - (rect.top + rect.height / 2)) / reach))
    stick.hold(offset, event.timeStamp)
    setGrip(offset * reach)
  }

  function release() {
    stick.release()
    setGrip(null)
  }

  return (
    <div className="touchpad glass">
      <div
        className="touchpad-area"
        aria-label="Touchpad"
        onPointerDown={(event) => {
          event.currentTarget.setPointerCapture(event.pointerId)
          gesture.down(event.pointerId, event.clientX, event.clientY, event.timeStamp)
        }}
        onPointerMove={(event) => gesture.move(event.pointerId, event.clientX, event.clientY, event.timeStamp)}
        onPointerUp={(event) => gesture.up(event.pointerId, event.timeStamp)}
        onPointerCancel={(event) => gesture.cancel(event.pointerId)}
      />
      <div
        className="touchpad-strip"
        aria-label="Rolagem"
        onPointerDown={(event) => {
          event.currentTarget.setPointerCapture(event.pointerId)
          hold(event)
        }}
        onPointerMove={(event) => { if (grip !== null) hold(event) }}
        onPointerUp={release}
        onPointerCancel={release}
      >
        <span className={grip === null ? 'grip' : 'grip held'} style={{ transform: `translateY(${grip ?? 0}px)` }} />
      </div>
    </div>
  )
}
