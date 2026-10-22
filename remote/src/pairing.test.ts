import { describe, expect, it } from 'vitest'
import { clearToken, resolveToken } from './pairing'

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

describe('resolveToken', () => {
  it('takes the token from the URL and saves it', () => {
    const storage = memoryStorage({ 'cinekit.token': 'old' })
    expect(resolveToken(new URL('http://sala.local:8686/?token=new'), storage)).toBe('new')
    expect(storage.getItem('cinekit.token')).toBe('new')
  })

  it('falls back to the saved token', () => {
    const storage = memoryStorage({ 'cinekit.token': 'saved' })
    expect(resolveToken(new URL('http://sala.local:8686/'), storage)).toBe('saved')
  })

  it('is null with no token anywhere', () => {
    expect(resolveToken(new URL('http://sala.local:8686/'), memoryStorage())).toBeNull()
  })
})

describe('clearToken', () => {
  it('forgets the saved token', () => {
    const storage = memoryStorage({ 'cinekit.token': 'saved' })
    clearToken(storage)
    expect(storage.getItem('cinekit.token')).toBeNull()
  })
})
