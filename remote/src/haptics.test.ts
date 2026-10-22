import { describe, expect, it, vi } from 'vitest'
import { haptic } from './haptics'

/** Just the bits of the DOM `haptic` uses, without a browser. */
function fakeDocument() {
  const elements = new Map<string, { click: () => void }>()
  const created: Record<string, unknown>[] = []
  const document = {
    getElementById: (id: string) => elements.get(id) ?? null,
    createElement: (tag: string) => {
      const element: Record<string, unknown> = { tag, style: {}, setAttribute: vi.fn(), append: vi.fn(), click: vi.fn() }
      created.push(element)
      return element
    },
    body: {
      append: (element: { id?: string; click: () => void }) => {
        if (element.id) elements.set(element.id, element)
      },
    },
  }
  return { document: document as unknown as Document, created }
}

describe('haptic', () => {
  it('uses navigator.vibrate when present', () => {
    const vibrate = vi.fn()
    const { document, created } = fakeDocument()
    haptic({ navigator: { vibrate }, document })
    expect(vibrate).toHaveBeenCalledWith(10)
    expect(created).toEqual([])
  })

  it('clicks the switch label without vibrate', () => {
    const { document, created } = fakeDocument()
    haptic({ navigator: {}, document })
    haptic({ navigator: {}, document })
    const label = created.find((element) => element.tag === 'label')!
    expect(label.click).toHaveBeenCalledTimes(2)
    expect(created.filter((element) => element.tag === 'label')).toHaveLength(1)
  })

  it('does nothing and does not throw without either', () => {
    expect(() => haptic({})).not.toThrow()
  })
})
