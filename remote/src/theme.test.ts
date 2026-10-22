import { describe, expect, it } from 'vitest'
import { applyTheme, loadTheme, saveTheme } from './theme'

function memoryStorage(initial: Record<string, string> = {}): Storage {
  const items = new Map(Object.entries(initial))
  return {
    get length() { return items.size },
    clear: () => items.clear(),
    getItem: (key) => items.get(key) ?? null,
    key: (index) => [...items.keys()][index] ?? null,
    removeItem: (key) => { items.delete(key) },
    setItem: (key, value) => { items.set(key, value) },
  }
}

describe('loadTheme', () => {
  it('is dark with nothing saved', () => {
    expect(loadTheme(memoryStorage())).toBe('dark')
  })

  it('returns the saved theme', () => {
    expect(loadTheme(memoryStorage({ 'cinekit.theme': 'light' }))).toBe('light')
  })

  it('is dark with an unknown value saved', () => {
    expect(loadTheme(memoryStorage({ 'cinekit.theme': 'system' }))).toBe('dark')
  })
})

describe('saveTheme', () => {
  it('saves the theme', () => {
    const storage = memoryStorage()
    saveTheme('light', storage)
    expect(storage.getItem('cinekit.theme')).toBe('light')
  })
})

describe('applyTheme', () => {
  it('sets data-theme and the theme color', () => {
    const meta = { content: '' }
    const doc = {
      documentElement: { dataset: {} as DOMStringMap },
      querySelector: (selector: string) => (selector === 'meta[name="theme-color"]' ? meta : null),
    } as unknown as Document
    applyTheme('light', doc)
    expect(doc.documentElement.dataset.theme).toBe('light')
    expect(meta.content).toBe('#f2f2f7')
    applyTheme('dark', doc)
    expect(doc.documentElement.dataset.theme).toBe('dark')
    expect(meta.content).toBe('#000000')
  })
})
